require "document"
require "logger"
require "cgi"
require "rest-client"
require "multi_json"
require "json"
require "elasticsearch/advanced_search_query_builder"
require "elasticsearch/client"

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

    attr_reader :mappings, :index_name

    def initialize(base_uri, index_name, mappings, logger = nil)
      @client = Client.new(base_uri + "#{CGI.escape(index_name)}/", logger)
      @index_name = index_name
      raise ArgumentError, "Missing index_name parameter" unless @index_name
      @mappings = mappings
      @logger = logger || Logger.new("/dev/null")
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
      @logger.info "Adding #{documents.size} document(s) to elasticsearch"
      documents = documents.map(&:elasticsearch_export).map do |doc|
        index_action(doc).to_json + "\n" + doc.to_json
      end
      # Ensure the request payload ends with a newline
      @client.post("_bulk", documents.join("\n") + "\n", content_type: :json)
    end

    def populate_from(source_index)
      total_indexed = 0
      # This will load the entire content of the search index into memory at
      # once, which isn't yet a big deal but may become a problem as the search
      # index grows. One alternative could be to use elasticsearch scan queries
      # <http://www.elasticsearch.org/guide/reference/api/search/search-type.html>
      all_docs = source_index.all_documents
      all_docs.each_slice(self.class.populate_batch_size) do |documents|
        add documents
        total_indexed += documents.length
        @logger.info "Populated #{total_indexed} of #{all_docs.size}"
      end

      commit
    end

    def get(link)
      @logger.info "Retrieving document with link '#{link}'"
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
      search_uri = URI::Generic.build(
        path: "_search",
        query: URI.encode_www_form(
          search_type: "scan",
          scroll: "#{SCROLL_TIMEOUT_MINUTES}m",
          size: self.class.scroll_batch_size
        )
      )
      scroll_response = @client.get_with_payload(search_uri, search_body.to_json)
      scroll_result = MultiJson.decode(scroll_response)
      scroll_id = scroll_result["_scroll_id"]

      total_hits = scroll_result["hits"]["total"]

      result_page_uri = URI::Generic.build(
        # Scrolling is accessed from the server root, not an index
        path: "/_search/scroll",
        query: URI.encode_www_form(
          scroll: "#{SCROLL_TIMEOUT_MINUTES}m",
          scroll_id: scroll_id
        )
      )

      # Pull out the results as they are needed
      SizedEnumerator.new(total_hits) do |yielder|
        loop do
          begin
            response = @client.get(result_page_uri)
          rescue RestClient::InternalServerError => e
            # elasticsearch returns a 500 status code if any of the shards
            # encountered an error (for example, running off the end of the
            # scroll), but this doesn't necessarily mean there aren't any more
            # results.
            response = e.response
          end

          page = MultiJson.decode(response)
          # The way we tell we've got through all the results is when
          # elasticsearch gives us an empty array of hits. This means all the
          # shards have run out of results.
          if page["hits"]["hits"].any?
            page["hits"]["hits"].each do |hit|
              yielder << document_from_hash(hit["_source"])
            end
          else
            break
          end
        end
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

      query_boosts = shingle_boosts

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
                should: query_boosts
              }
            },
            filters: format_boosts + [time_boost]
          }
        }
      }.to_json

      @logger.debug "Request payload: #{payload}"
      result = @client.get_with_payload("_search", payload)
      result = MultiJson.decode(result)
      result["hits"]["hits"].map { |hit|
        document_from_hash(hit["_source"].merge("es_score" => hit["_score"]))
      }
    end

    def advanced_search(params)
      @logger.info "params:#{params.inspect}"
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

      @logger.info "Request payload: #{payload.to_json}"

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
    def index_action(doc)
      {"index" => {"_type" => doc["_type"], "_id" => doc["link"]}}
    end
  end
end
