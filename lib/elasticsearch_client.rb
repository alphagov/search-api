module ElasticsearchClient
  class << self
    def compatible_mappings(properties)
      return { "properties" => properties } if es7?

      { "generic-document" => { "properties" => properties } }
    end

    def search(index_name:, body:, client: Services.elasticsearch)
      client.search(compatible_params(index: index_name, body:))
    end

    def index(id:, index_name:, atts:, params: {}, client: Services.elasticsearch)
      client.index(compatible_params(index: index_name, id:, body: atts).merge(params))
    end

    def es7?
      return true if ENV["USE_ELASTICSEARCH_7"]
      return false if ENV["USE_ELASTICSEARCH_6"]

      es_version >= Gem::Version.new("7.0.0")
    end

    def reload_version
      @es_version = nil
    end

  private

    def compatible_params(params)
      return params if es7?

      params.merge(type: "generic-document")
    end

    def es_version
      @es_version ||= Gem::Version.new(Services.elasticsearch.info.dig("version", "number"))
    end
  end
end
