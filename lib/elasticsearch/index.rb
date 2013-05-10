require "document"
require "logging"
require "cgi"
require "rest-client"
require "multi_json"
require "json"
require "elasticsearch/advanced_search_query_builder"
require "elasticsearch/client"
require "elasticsearch/scroll_enumerator"

module Elasticsearch
  class Index

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

    # How long to hold a scroll cursor open between requests
    # We should be able to keep this low, since these are only for internal use
    SCROLL_TIMEOUT_MINUTES = 1

    # How long to wait between reads when streaming data from the elasticsearch server
    TIMEOUT_SECONDS = 5.0

    # How long to wait for a connection to the elasticsearch server
    OPEN_TIMEOUT_SECONDS = 5.0

    attr_reader :mappings, :index_name

    def initialize(base_uri, index_name, mappings)
      @client = Client.new(
        base_uri + "#{CGI.escape(index_name)}/",
        timeout: TIMEOUT_SECONDS,
        open_timeout: OPEN_TIMEOUT_SECONDS
      )
      @index_name = index_name
      raise ArgumentError, "Missing index_name parameter" unless @index_name
      @mappings = mappings
    end

    def field_names
      @mappings["edition"]["properties"].keys
    end

    def real_name
      alias_info = MultiJson.decode(@client.get("_aliases"))
      # If the index exists, it will return something of the form:
      # { real_name => { "aliases" => { alias => {} } } }
      # If not, it'll return:
      # {}
      alias_info.keys.first
    end

    def exists?
      ! real_name.nil?
    end

    def add(documents)
      if documents.size == 1
        logger.info "Adding #{documents.size} document to #{index_name}"
      else
        logger.info "Adding #{documents.size} documents to #{index_name}"
      end
      documents = documents.map(&:elasticsearch_export).map do |doc|
        index_action(doc).to_json + "\n" + doc.to_json
      end
      # Ensure the request payload ends with a newline
      @client.post("_bulk", documents.join("\n") + "\n", content_type: :json)
    end

    def populate_from(source_index)
      total_indexed = 0
      all_docs = source_index.all_documents
      all_docs.each_slice(self.class.populate_batch_size) do |documents|
        add documents
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
      logger.info "Retrieving document with link '#{link}'"
      begin
        response = @client.get("_all/#{CGI.escape(link)}")
      rescue RestClient::ResourceNotFound
        return nil
      end

      document_from_hash(MultiJson.decode(response.body)["_source"])
    end

    def document_from_hash(hash)
      Document.from_hash(hash, @mappings)
    end

    def all_documents
      # Set off a scan query to get back a scroll ID and result count
      search_body = {query: {match_all: {}}}
      batch_size = self.class.scroll_batch_size
      ScrollEnumerator.new(@client, search_body, batch_size) do |hit|
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
        hit["fields"]["link"]
      end
    end

    def search(query)
      # Per-format boosting done as a filter, so the results get cached on the
      # server, as they are the same for each query

      boosted_formats = {
        # Mainstream formats
        "smart-answer"  => 1.5,
        "transaction"   => 1.5,
        # Inside Gov formats
        "topical_event" => 1.5,
        "minister"      => 1.7,
        "organisation"  => 2.5,
        "topic"         => 1.5,
        "document_series" => 1.3,
        "operational_field" => 1.5,
      }

      format_boosts = boosted_formats.map do |format, boost|
        {
          filter: { term: { format: format } },
          boost: boost
        }
      end

      # An implementation of http://wiki.apache.org/solr/FunctionQuery#recip
      # Curve for 2 months: http://www.wolframalpha.com/share/clip?f=d41d8cd98f00b204e9800998ecf8427e5qr62u0si
      #
      # Behaves as a freshness boost for newer documents with a public_timestamp and search_format_types announcement
      time_boost = {
        filter: { term: { search_format_types: "announcement" } },
        script: "((0.05 / ((3.16*pow(10,-11)) * abs(time() - doc['public_timestamp'].date.getMillis()) + 0.05)) + 0.12)"
      }

      query_analyzer = "query_default"

      match_fields = {
        "title" => 5,
        "description" => 2,
        "indexable_content" => 1,
      }

      # "driving theory test" => ["driving theory", "theory test"]
      shingles = query.split.each_cons(2).map { |s| s.join(' ') }

      # These boosts will be different on each query, so there's no benefit to
      # caching them in a filter
      shingle_boosts = shingles.map do |shingle|
        match_fields.map do |field_name, _|
          {
            text: {
              field_name => {
                query: shingle,
                type: "phrase",
                boost: 2,
                analyzer: query_analyzer
              },
            }
          }
        end
      end

      payload = {
        from: 0, size: 50,
        query: {
          custom_filters_score: {
            query: {
              bool: {
                must: {
                  query_string: {
                    fields: match_fields.map { |name, boost|
                      boost == 1 ? name : "#{name}^#{boost}"
                    },
                    query: escape(query),
                    analyzer: query_analyzer
                  }
                },
                should: shingle_boosts
              }
            },
            filters: format_boosts + [time_boost]
          }
        }
      }.to_json

      logger.debug "Request payload: #{payload}"
      result = @client.get_with_payload("_search", payload)
      result = MultiJson.decode(result)
      result["hits"]["hits"].map { |hit|
        document_from_hash(hit["_source"].merge("es_score" => hit["_score"]))
      }
    end

    def advanced_search(params)
      logger.info "params:#{params.inspect}"
      raise "Pagination params are required." if params["per_page"].nil? || params["page"].nil?

      order     = params.delete("order")
      format    = params.delete("format")
      backend   = params.delete("backend")
      keywords  = params.delete("keywords")
      per_page  = params.delete("per_page").to_i
      page      = params.delete("page").to_i

      query_builder = AdvancedSearchQueryBuilder.new(keywords, params, order, @mappings)
      raise query_builder.error unless query_builder.valid?

      starting_index = page <= 1 ? 0 : (per_page * (page - 1))
      payload = {
        "from" => starting_index,
        "size" => per_page
      }

      payload.merge!(query_builder.query_hash)

      logger.info "Request payload: #{payload.to_json}"

      result = @client.get_with_payload("_search", payload.to_json)
      result = MultiJson.decode(result)
      {
        total: result["hits"]["total"],
        results: result["hits"]["hits"].map { |hit|
          document_from_hash(hit["_source"].merge("es_score" => hit["_score"]))
        }
      }
    end

    LUCENE_SPECIAL_CHARACTERS = Regexp.new("(" + %w[
      + - && || ! ( ) { } [ ] ^ " ~ * ? : \\
    ].map { |s| Regexp.escape(s) }.join("|") + ")")

    LUCENE_BOOLEANS = /\b(AND|OR|NOT)\b/

    def escape(s)
      # 6 slashes =>
      #  ruby reads it as 3 backslashes =>
      #    the first 2 =>
      #      go into the regex engine which reads it as a single literal backslash
      #    the last one combined with the "1" to insert the first match group
      special_chars_escaped = s.gsub(LUCENE_SPECIAL_CHARACTERS, '\\\\\1')

      # Map something like 'fish AND chips' to 'fish "AND" chips', to avoid
      # Lucene trying to parse it as a query conjunction
      special_chars_escaped.gsub(LUCENE_BOOLEANS, '"\1"')
    end

    def delete(link)
      begin
        # Can't use a simple delete, because we don't know the type
        @client.delete "_query", params: {q: "link:#{escape(link)}"}
      rescue RestClient::ResourceNotFound
      end
      return true  # For consistency with the Solr API and simple_json_response
    end

    def delete_by_format(format)
      @client.delete_with_payload("_query", {term: {format: format}}.to_json)
    end

    def delete_all
      @client.delete_with_payload("_query", {match_all: {}}.to_json)
      commit
    end

    def commit
      @client.post "_refresh", nil
    end

    private
    def logger
      Logging.logger[self]
    end

    def index_action(doc)
      {"index" => {"_type" => doc["_type"], "_id" => doc["link"]}}
    end
  end
end
