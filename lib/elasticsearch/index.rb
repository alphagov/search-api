require "document"
require "logging"
require "cgi"
require "rest-client"
require "json"
require "elasticsearch/advanced_search_query_builder"
require "elasticsearch/client"
require "elasticsearch/index_queue"
require "elasticsearch/escaping"
require "elasticsearch/result_set"
require "elasticsearch/scroll_enumerator"
require "elasticsearch/search_query_builder"

module Elasticsearch
  class InvalidQuery < ArgumentError; end
  class DocumentNotFound < RuntimeError; end
  class IndexLocked < RuntimeError; end

  class BulkIndexFailure < RuntimeError
    attr_reader :failed_keys

    def initialize(failed_keys)
      super "Failed inserts: #{failed_keys.join(', ')}"
      @failed_keys = failed_keys
    end
  end

  class Index
    include Elasticsearch::Escaping

    # An enumerator with a manually-specified size.
    # This means we can count the number of documents in an index without
    # having to load them all.
    class SizedEnumerator < Enumerator
      attr_reader :size

      def initialize(size, &block)
        super(&block)
        @size = size
      end
    end

    # The number of documents to insert at once when populating
    def self.populate_batch_size
      50
    end

    # The number of documents to retrieve at once when retrieving all documents
    # Gotcha: this is actually the number of documents per shard, so there will
    # be up to some multiple of this number per page.
    def self.scroll_batch_size
      50
    end

    # How long to wait between reads when streaming data from the elasticsearch server
    TIMEOUT_SECONDS = 5.0

    # How long to wait for a connection to the elasticsearch server
    OPEN_TIMEOUT_SECONDS = 5.0

    # Extra-long timeouts for migrations, since we're more worried about these
    # completing reliably than completing quickly
    LONG_TIMEOUT_SECONDS = TIMEOUT_SECONDS * 3
    LONG_OPEN_TIMEOUT_SECONDS = OPEN_TIMEOUT_SECONDS * 3

    attr_reader :mappings, :index_name

    def initialize(base_uri, index_name, mappings, search_config)
      # Save this for if and when we want to build custom Clients
      @index_uri = base_uri + "#{CGI.escape(index_name)}/"

      @client = build_client
      @index_name = index_name
      raise ArgumentError, "Missing index_name parameter" unless @index_name
      @mappings = mappings
      @search_config = search_config
      @is_content_index = !(@search_config.auxiliary_index_names.include? @index_name)
    end

    def field_names
      @mappings["edition"]["properties"].keys
    end

    def real_name
      # If the index exists, it will return something of the form:
      # { real_name => { "aliases" => { alias => {} } } }
      # If not, ES would return {} before version 0.90, but raises a 404 with version 0.90+
      begin
        alias_info = JSON.parse(@client.get("_aliases"))
      rescue RestClient::ResourceNotFound => e
        response_body = JSON.parse(e.http_body)
        if response_body['error'].start_with?("IndexMissingException") then
          return nil
        end
        raise
      end

      alias_info.keys.first
    end

    def exists?
      ! real_name.nil?
    end

    def close
      @client.post("_close", nil)
    end

    # Apply a write lock to this index, making it read-only
    def lock
      request_body = {"index" => {"blocks" => {"write" => true}}}.to_json
      @client.put("_settings", request_body, content_type: :json)
    end

    # Remove any write lock applied to this index
    def unlock
      request_body = {"index" => {"blocks" => {"write" => false}}}.to_json
      @client.put("_settings", request_body, content_type: :json)
    end

    def with_lock(&block)
      logger.info "Locking #{@index_name}"
      lock
      begin
        block.call
      ensure
        logger.info "Unlocking #{@index_name}"
        unlock
      end
    end

    def add(documents, options = {})
      if documents.size == 1
        logger.info "Adding #{documents.size} document to #{index_name}"
      else
        logger.info "Adding #{documents.size} documents to #{index_name}"
      end

      document_hashes = documents.map { |d| d.elasticsearch_export }
      bulk_index(document_hashes, options)
    end

    # Add documents asynchronously to the index.
    def add_queued(documents)
      noun = documents.size > 1 ? "documents" : "document"
      logger.info "Queueing #{documents.size} #{noun} to add to #{index_name}"

      document_hashes = documents.map { |d| d.elasticsearch_export }
      queue.queue_many(document_hashes)
    end

    def bulk_index(document_hashes_or_payload, options = {} )
      client = build_client(options)
      response = client.post("_bulk", bulk_payload(document_hashes_or_payload, options), content_type: :json)
      items = JSON.parse(response.body)["items"]
      failed_items = items.select do |item|
        data = item["index"] || item["create"]
        data.has_key?("error")
      end
      if failed_items.any?
        # Because bulk writes return a 200 status code regardless, we need to
        # parse through the errors to detect responses that indicate a locked
        # index
        blocked_items = failed_items.select { |item|
          locked_index_error?(item["index"]["error"])
        }
        if blocked_items.any?
          raise IndexLocked
        else
          # TODO This error should include the error messages from
          # elasticsearch, not just the IDs of the documents that weren't
          # inserted
          raise BulkIndexFailure.new(failed_items.map { |item| item["index"]["_id"] })
        end
      end
      response
    end

    def amend(link, updates)
      document = get(link)
      raise DocumentNotFound.new(link) unless document

      if updates.include? "link"
        raise ArgumentError.new("Cannot change document links")
      end

      updates.each do |key, value|
        if document.has_field?(key)
          document.set key, value
        else
          raise ArgumentError.new("Unrecognised field '#{key}'")
        end
      end
      add [document]
      return true
    end

    def amend_queued(link, updates)
      queue.queue_amend(link, updates)
    end

    def populate_from(source_index, option_overrides = {})
      total_indexed = 0
      options = {
        timeout: LONG_TIMEOUT_SECONDS,
        open_timeout: LONG_OPEN_TIMEOUT_SECONDS,
      }.merge(option_overrides)
      all_docs = source_index.all_documents(options)
      all_docs.each_slice(self.class.populate_batch_size) do |documents|
        add(documents, options)
        total_indexed += documents.length
        logger.info do
          progress = "#{total_indexed}/#{all_docs.size}"
          source_name = source_index.index_name
          "Populated #{progress} from #{source_name} into #{index_name}"
        end
      end

      commit
    end

    def get(link)
      type, id = link_to_type_and_id(link)
      logger.info "Retrieving document of type '#{type}', id '#{id}'"
      begin
        response = @client.get("#{CGI.escape(type)}/#{CGI.escape(id)}")
      rescue RestClient::ResourceNotFound
        return nil
      end

      document_from_hash(JSON.parse(response.body)["_source"])
    end

    def document_from_hash(hash)
      Document.from_hash(hash, @mappings)
    end

    def all_documents(options = nil)
      client = options ? build_client(options) : @client

      # Set off a scan query to get back a scroll ID and result count
      search_body = {query: {match_all: {}}}
      batch_size = self.class.scroll_batch_size
      ScrollEnumerator.new(client, search_body, batch_size) do |hit|
        document_from_hash(hit["_source"])
      end
    end

    def all_document_links(exclude_formats = [])
      search_body = {
        "query" => {
          "bool" => {
            "must_not" => {
              "terms" => {
                "format" => exclude_formats
              }
            }
          }
        },
        "fields" => ["link"]
      }

      batch_size = self.class.scroll_batch_size
      ScrollEnumerator.new(@client, search_body, batch_size) do |hit|
        hit.fetch("fields", {})["link"]
      end
    end

    # `options` can have the following keys:
    #   :fields - a list of field names to be included in the document, if not
    #             specified, the mappings are used.
    def documents_by_format(format, options = {})
      batch_size = 500
      search_body = {query: {term: {format: format}}}
      if options[:fields]
        search_body.merge!(fields: options[:fields])
        field_names = options[:fields]
        result_key = "fields"
      else
        # Use all field names from the mappings
        # TODO: remove duplication between this and Document.from_hash
        field_names = @mappings["edition"]["properties"].keys.map(&:to_s)
        result_key = "_source"
      end

      ScrollEnumerator.new(@client, search_body, batch_size) do |hit|
        Document.new(field_names, hit[result_key])
      end
    end

    def search(keywords, options={})
      builder = SearchQueryBuilder.new(keywords, @mappings, options)
      raise InvalidQuery.new(builder.error) unless builder.valid?
      ResultSet.from_elasticsearch(@mappings, raw_search(builder.query_hash))
    end

    def advanced_search(params)
      logger.info "params:#{params.inspect}"
      if params["per_page"].nil? || params["page"].nil?
        raise InvalidQuery.new("Pagination params are required.")
      end

      # Delete params that we don't want to be passed as filter_params
      order     = params.delete("order")
      keywords  = params.delete("keywords")
      per_page  = params.delete("per_page").to_i
      page      = params.delete("page").to_i

      query_builder = AdvancedSearchQueryBuilder.new(keywords, params, order, @mappings)
      raise InvalidQuery.new(query_builder.error) unless query_builder.valid?

      starting_index = page <= 1 ? 0 : (per_page * (page - 1))
      payload = {
        "from" => starting_index,
        "size" => per_page
      }

      payload.merge!(query_builder.query_hash)

      ResultSet.from_elasticsearch(@mappings, raw_search(payload))
    end

    def raw_search(payload, type=nil)
      json_payload = payload.to_json
      logger.debug "Request payload: #{json_payload}"
      if type.nil?
        path = "_search"
      else
        path = "#{type}/_search"
      end
      JSON.parse(@client.get_with_payload(path, json_payload))
    end

    # Convert a best bet query to a string formed by joining the normalised
    # words in the query with spaces.
    def analyzed_best_bet_query(query)
      analyzed_query = JSON.parse(@client.get_with_payload(
        "_analyze?analyzer=best_bet_stemmed_match", query))

      analyzed_query["tokens"].map { |token_info|
        token_info["token"]
      }.join(" ")
    end

    def delete(type, id)
      begin
        @client.delete("#{CGI.escape(type)}/#{CGI.escape(id)}")
      rescue RestClient::ResourceNotFound
      rescue RestClient::Forbidden => e
        response_body = JSON.parse(e.http_body)
        if locked_index_error?(response_body["error"])
          raise IndexLocked
        else
          raise
        end
      end
      return true  # For consistency with the Solr API and simple_json_response
    end

    def delete_queued(document_type, document_id)
      queue.queue_delete(document_type, document_id)
    end

    def delete_all
      @client.delete_with_payload("_query", {match_all: {}}.to_json)
      commit
    end

    def commit
      @client.post "_refresh", nil
    end

    def link_to_type_and_id(link)
      # If link starts with edition/ or best-bet/ then use those values for the
      # type.  For backwards compact, if it starts with anything else currently
      # assume that the type is edition.
      if (m = link.match(/\A(edition|best_bet)\/(.*)\Z/))
        return [m[1], m[2]]
      else
        return ["edition", link]
      end
    end

  private

    # Parse an elasticsearch error message to determine whether it's caused by
    # a write-locked index. An example write-lock error message:
    #
    #     "ClusterBlockException[blocked by: [FORBIDDEN/8/index write (api)];]"
    def locked_index_error?(error_message)
      error_message =~ %r{\[FORBIDDEN/[^/]+/index write}
    end

    def logger
      Logging.logger[self]
    end

    def index_items_from_document_hashes(document_hashes, options)
      links = document_hashes.map {
        |doc_hash| doc_hash["link"]
      }.compact
      popularities = lookup_popularities(links)
      document_hashes.map { |doc_hash|
        [index_action(doc_hash).to_json, index_doc(doc_hash, popularities, options).to_json]
      }
    end

    def index_items_from_raw_string(payload, options)
      actions = []
      links = []
      payload.each_line.each_slice(2).map do |command, doc|
        command_hash = JSON.parse(command)
        doc_hash = JSON.parse(doc)
        actions << [command_hash, doc_hash]
        links << doc_hash["link"]
      end
      popularities = lookup_popularities(links.compact)
      actions.map { |command_hash, doc_hash|
        if command_hash.keys == ["index"]
          doc_hash["_type"] = command_hash["index"]["_type"]
          [
            command_hash.to_json,
            index_doc(doc_hash, popularities, options).to_json
          ]
        else
          [
            command_hash.to_json,
            doc_hash.to_json
          ]
        end
      }
    end

    # Payload to index documents using the `_bulk` endpoint
    #
    # The format is as follows:
    #
    #   {"index": {"_type": "edition", "_id": "/bank-holidays"}}
    #   { <document source> }
    #   {"index": {"_type": "edition", "_id": "/something-else"}}
    #   { <document source> }
    #
    # See <http://www.elasticsearch.org/guide/reference/api/bulk/>
    def bulk_payload(document_hashes_or_payload, options)
      if document_hashes_or_payload.is_a?(Array)
        index_items = index_items_from_document_hashes(document_hashes_or_payload, options)
      else
        index_items = index_items_from_raw_string(document_hashes_or_payload, options)
      end

      # Make sure the payload ends with a newline character: elasticsearch
      # requires this.
      index_items.flatten.join("\n") + "\n"
    end

    def index_action(doc_hash)
      {
        "index" => {
          "_type" => doc_hash["_type"],
          "_id" => (doc_hash["_id"] || doc_hash["link"])
        }
      }
    end

    def index_doc(doc_hash, popularities, options)
      if @is_content_index
        doc_hash = prepare_popularity_field(doc_hash, popularities)
        doc_hash = prepare_mainstream_browse_page_field(doc_hash)
        doc_hash = prepare_tag_field(doc_hash)
        doc_hash = prepare_format_field(doc_hash)
      end

      doc_hash = prepare_if_best_bet(doc_hash)
      doc_hash
    end

    def prepare_popularity_field(doc_hash, popularities)
      pop = 0.0
      unless popularities.nil?
        link = doc_hash["link"]
        pop = popularities[link]
      end
      doc_hash.merge("popularity" => pop)
    end

    def prepare_mainstream_browse_page_field(doc_hash)
      # Mainstream browse pages were modelled as three separate fields:
      # section, subsection and subsubsection.  This is unhelpful in many ways,
      # so model them instead as a single field containing the full path.
      #
      # In future, we'll get them in this form directly, at which point we'll
      # also be able to there may be multiple browse pages tagged to a piece of
      # content.
      return doc_hash if doc_hash["mainstream_browse_pages"]

      path = [
        doc_hash["section"],
        doc_hash["subsection"],
        doc_hash["subsubsection"]
      ].compact.join("/")

      if path == ""
        doc_hash
      else
        doc_hash.merge("mainstream_browse_pages" => [path])
      end
    end

    def prepare_tag_field(doc_hash)
      tags = []

      tags.concat(Array(doc_hash["organisations"]).map { |org| "organisation:#{org}" })
      tags.concat(Array(doc_hash["specialist_sectors"]).map { |sector| "sector:#{sector}" })

      doc_hash.merge("tags" => tags)
    end

    def prepare_format_field(doc_hash)
      if doc_hash["format"].nil?
        doc_hash.merge("format" => doc_hash["_type"])
      else
        doc_hash
      end
    end

    # If a document is a best bet, and is using the stemmed_query field, we
    # need to populate the stemmed_query_as_term field with a processed version
    # of the field.  This produces a representation of the best-bet query with
    # all words stemmed and lowercased, and joined with a single space.
    #
    # At search time, all best bets with at least one word in common with the
    # user's query are fetched, and the stemmed_query_as_term field of each is
    # checked to see if it is a substring match for the (similarly normalised)
    # user's query.  If so, the best bet is used.
    def prepare_if_best_bet(doc_hash)
      if doc_hash["_type"] != "best_bet"
        return doc_hash
      end

      stemmed_query = doc_hash["stemmed_query"]
      if stemmed_query.nil?
        return doc_hash
      end

      doc_hash["stemmed_query_as_term"] = " #{analyzed_best_bet_query(stemmed_query)} "
      doc_hash
    end

    def lookup_popularities(links)
      if traffic_index.nil?
        return nil
      end
      results = traffic_index.raw_search({
        query: {
          terms: {
            path_components: links
          }
        },
        fields: ["rank_14"],
        sort: [
          { rank_14: { order: "asc" }}
        ],
        size: 10 * links.size,
      })
      ranks = Hash.new(traffic_index_size)
      results["hits"]["hits"].each do |hit|
        link = hit["_id"]
        rank = hit["fields"]["rank_14"]
        if rank.nil?
          next
        end
        ranks[link] = [rank, ranks[link]].min
      end

      Hash[links.map { |link|
        popularity_score = (ranks[link] == 0) ? 0 : (1.0 / ranks[link])
        [link, popularity_score]
      }]
    end

    def traffic_index
      if @opened_traffic_index
        return @traffic_index
      end
      @traffic_index = open_traffic_index
      @opened_traffic_index = true
      return @traffic_index
    end

    def traffic_index_size
      results = traffic_index.raw_search({
        query: { match_all: {}},
        size: 0
      })
      results["hits"]["total"]
    end

    def open_traffic_index
      if @index_name.start_with?("page-traffic")
        return nil
      end

      traffic_index_name = @search_config.auxiliary_index_names.find {|index|
        index.start_with?("page-traffic")
      }

      if traffic_index_name
        result = @search_config.search_server.index(traffic_index_name)

        if result.exists?
          return result
        end
      end

      return nil
    end

    def queue
      IndexQueue.new(index_name)
    end

    def build_client(options={})
      Client.new(
        @index_uri,
        timeout: options[:timeout] || TIMEOUT_SECONDS,
        open_timeout: options[:open_timeout] || OPEN_TIMEOUT_SECONDS
      )
    end
  end
end
