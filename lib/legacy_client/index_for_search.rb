module LegacyClient
  class IndexForSearch
    attr_reader :index_names, :schema

    # How long to wait between reads when streaming data from the elasticsearch server
    TIMEOUT_SECONDS = 5.0

    def initialize(base_uri, index_names, schema, search_config)
      @base_uri = base_uri
      @client = build_client
      @index_names = index_names
      @schema = schema
      @search_config = search_config
    end

    def real_index_names
      index_names.map do |index_name|
        # this may throw an exception if the index name isn't found,
        # but we want to propagate the error in that case as it
        # shouldn't happen.
        @client.indices.get_alias(index: index_name).keys.first
      end
    end

    def raw_search(payload)
      logger.debug "Request payload: #{payload.to_json}"
      @client.search(index: @index_names, type: 'generic-document', body: payload)
    end

    def get_document_by_link(link)
      results = raw_search(query: { term: { link: link } }, size: 1)
      raw_result = results['hits']['hits'].first

      if raw_result
        raw_result['real_index_name'] = SearchIndices::Index.strip_alias_from_index_name(raw_result['_index'])
      end

      raw_result
    end

    def msearch(bodies)
      payload = bodies.flat_map { |body|
        [
          {},
          body
        ]
      }
      logger.debug "Request payload: #{payload.to_json}"
      @client.msearch(index: @index_names, body: payload)
    end

    def documents_by_format(format, field_definitions)
      batch_size = 500
      search_body = {
        query: { term: { format: format } },
        _source: { includes: field_definitions.keys },
      }

      ScrollEnumerator.new(client: @client, search_body: search_body, batch_size: batch_size, index_names: @index_names) do |hit|
        MultivalueConverter.new(hit["_source"], field_definitions).converted_hash
      end
    end

  private

    def logger
      Logging.logger[self]
    end

    def build_client(options = {})
      Services.elasticsearch(hosts: @base_uri, timeout: options[:timeout] || TIMEOUT_SECONDS)
    end
  end
end
