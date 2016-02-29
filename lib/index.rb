require "logging"
require "cgi"
require "json"
require "rest-client"
require "legacy_client/client"
require "legacy_client/multivalue_converter"
require "legacy_client/scroll_enumerator"
require "legacy_search/advanced_search"
require "search/escaping"
require "search/result_set"
require "indexer"
require "indexer/amender"
require "document"
require "indexer/index_queue"

module SearchIndices
  class InvalidQuery < ArgumentError; end
  class DocumentNotFound < RuntimeError; end
  class IndexLocked < RuntimeError; end

  class BulkIndexFailure < RuntimeError
    attr_reader :failed_keys

    def initialize(failed_items)
      super "Failed inserts: #{failed_items.map { |id, error| "#{id} (#{error})" }.join(', ')}"
      @failed_keys = failed_items.map { |id, _| id }
    end
  end

  class Index
    include Search::Escaping

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

    attr_reader :mappings, :index_name

    def initialize(base_uri, index_name, base_index_name, mappings, search_config)
      # Save this for if and when we want to build custom Clients
      @index_uri = base_uri + "#{CGI.escape(index_name)}/"

      @client = build_client
      @index_name = index_name
      raise ArgumentError, "Missing index_name parameter" unless @index_name
      @mappings = mappings
      @search_config = search_config
      @document_types = @search_config.schema_config.document_types(base_index_name)
      @is_content_index = !(@search_config.auxiliary_index_names.include? base_index_name)
    end

    # Translate index names like `mainstream-2015-05-06t09..` into its
    # proper name, eg. "mainstream", "government" or "service-manual".
    # The regex takes the string until the first digit. After that, strip any
    # trailing dash from the string.
    def self.strip_alias_from_index_name(aliased_index_name)
      aliased_index_name.match(%r[^\D+]).to_s.chomp('-')
    end

    def real_name
      # If the index exists, it will return something of the form:
      # { real_name => { "aliases" => { alias => {} } } }
      # If not, ES would return {} before version 0.90, but raises a 404 with version 0.90+
      begin
        alias_info = JSON.parse(@client.get("_aliases"))
      rescue RestClient::ResourceNotFound => e
        response_body = JSON.parse(e.http_body)
        if response_body['error'].start_with?("IndexMissingException")
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
      request_body = { "index" => { "blocks" => { "write" => true } } }.to_json
      @client.put("_settings", request_body, content_type: :json)
    end

    # Remove any write lock applied to this index
    def unlock
      request_body = { "index" => { "blocks" => { "write" => false } } }.to_json
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
      logger.info "Adding #{documents.size} document(s) to #{index_name}"

      document_hashes = documents.map(&:elasticsearch_export)
      bulk_index(document_hashes, options)
    end

    # Add documents asynchronously to the index.
    def add_queued(documents)
      logger.info "Queueing #{documents.size} document(s) to add to #{index_name}"

      document_hashes = documents.map(&:elasticsearch_export)
      queue.queue_many(document_hashes)
    end

    # `bulk_index` is the only method that inserts/updates documents. The other
    # indexing-methods like `add`, `add_queued` and `amend` eventually end up
    # calling this method.
    def bulk_index(document_hashes_or_payload, options = {})
      client = build_client(options)
      payload_generator = Indexer::BulkPayloadGenerator.new(@index_name, @search_config, @client, @is_content_index)
      response = client.post("_bulk", payload_generator.bulk_payload(document_hashes_or_payload), content_type: :json)
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
          raise BulkIndexFailure.new(failed_items.map { |item|
            [
              item["index"]["_id"],
              item["index"]["error"],
            ]
          })
        end
      end
      response
    end

    def amend(link, updates)
      Indexer::Amender.new(self).amend(link, updates)
    end

    def amend_queued(link, updates)
      queue.queue_amend(link, updates)
    end

    def get(link)
      begin
        response = @client.get("_all/#{CGI.escape(link)}")
        document_from_hash(JSON.parse(response.body)["_source"])
      rescue RestClient::ResourceNotFound
        nil
      end
    end

    def document_from_hash(hash)
      Document.from_hash(hash, @document_types)
    end

    def all_documents(options = nil)
      client = options ? build_client(options) : @client

      # Set off a scan query to get back a scroll ID and result count
      search_body = { query: { match_all: {} } }
      batch_size = self.class.scroll_batch_size
      LegacyClient::ScrollEnumerator.new(client, search_body, batch_size) do |hit|
        document_from_hash(hit["_source"].merge("_id" => hit["_id"]))
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
      LegacyClient::ScrollEnumerator.new(@client, search_body, batch_size) do |hit|
        hit.fetch("fields", {})["link"]
      end
    end

    def documents_by_format(format, field_definitions)
      batch_size = 500
      search_body = {
        query: { term: { format: format } },
        fields: field_definitions.keys,
      }

      LegacyClient::ScrollEnumerator.new(@client, search_body, batch_size) do |hit|
        LegacyClient::MultivalueConverter.new(hit["fields"], field_definitions).converted_hash
      end
    end

    def advanced_search(params)
      LegacySearch::AdvancedSearch.new(@mappings, @document_types, @client).result_set(params)
    end

    def raw_search(payload, type = nil)
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
    #
    # duplicated in document_preparer.rb
    def analyzed_best_bet_query(query)
      analyzed_query = JSON.parse(
        @client.get_with_payload("_analyze?analyzer=best_bet_stemmed_match", query)
      )

      analyzed_query["tokens"].map { |token_info|
        token_info["token"]
      }.join(" ")
    end

    def delete(type, id)
      begin
        @client.delete("#{CGI.escape(type)}/#{CGI.escape(id)}")
      rescue RestClient::ResourceNotFound
        # We are fine with trying to delete deleted documents.
        true
      rescue RestClient::Forbidden => e
        response_body = JSON.parse(e.http_body)
        if locked_index_error?(response_body["error"])
          raise IndexLocked
        else
          raise
        end
      end

      true # For consistency with the Solr API and simple_json_response
    end

    def delete_queued(document_type, document_id)
      queue.queue_delete(document_type, document_id)
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

    def queue
      Indexer::IndexQueue.new(index_name)
    end

    def build_client(options = {})
      LegacyClient::Client.new(
        @index_uri,
        timeout: options[:timeout] || TIMEOUT_SECONDS,
        open_timeout: options[:open_timeout] || OPEN_TIMEOUT_SECONDS
      )
    end
  end
end
