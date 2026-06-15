module ElasticsearchClient
  class << self
    def mappings_properties(mappings)
      return mappings if es7?

      mappings["generic-document"]
    end

    def compatible_mappings(properties)
      return { "properties" => properties } if es7?

      { "generic-document" => { "properties" => properties } }
    end

    def compatible_params(params)
      return params if es7?

      params.merge(type: "generic-document")
    end

    def compatible_identifier(params)
      return params if es7?

      params.merge("_type" => "generic-document")
    end

    def compatible_url(path, index: SearchConfig.govuk_index_name)
      type_path = es7? ? "" : "generic-document/"

      "http://example.com:9200/#{index}/#{type_path}#{path}"
    end

    def index(id:, index_name:, atts:, params: {}, client: Services.elasticsearch)
      client.index(compatible_params(index: index_name, id:, body: atts).merge(params))
    end

    def search(index_name:, body:, client: Services.elasticsearch)
      client.search(compatible_params(index: index_name, body:))
    end

    def delete(id:, index_name:, client: Services.elasticsearch)
      client.delete(compatible_params(index: index_name, id: id))
    end

    # TODO may be unnecessary
    def get(params, client: Services.elasticsearch)
      get_params = es7? ? params : params.merge(type: "_all")
      client.get(get_params)
    end

    def put_mapping(index_name:, mapping:, client: Services.elasticsearch)
      return client.indices.put_mapping(index: index_name, body: mapping) if es7?

      client.indices.put_mapping(index: index_name, type: "generic-document", body: mapping)
    end

    def es7?
      return true if ENV["USE_ELASTICSEARCH_7"]
      return false if ENV["USE_ELASTICSEARCH_6"]

      es_version >= Gem::Version.new('7.0.0')
    end

    private

    def es_version
      @es_version ||= Gem::Version.new(Services.elasticsearch.info.dig('version', 'number'))
    end
  end
end