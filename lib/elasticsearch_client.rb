module ElasticsearchClient
  class << self
    def search(index_name:, body:, client: Services.elasticsearch)
      return client.search(index: index_name, track_total_hits: true, body: body) if es7?

      client.search(index: index_name, type: "generic-document", body:)
    end

    def index(id:, index_name:, atts:, params: {}, client: Services.elasticsearch)
      client.index(compatible_params(index: index_name, id:, body: atts).merge(params))
    end

    def es7?
      return true if ENV["USE_ELASTICSEARCH_7"]
      return false if ENV["USE_ELASTICSEARCH_6"]

      return true if opensearch?

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

    def opensearch?
      Services.elasticsearch.info.dig("version", "distribution") == "opensearch"
    end

    def es_version
      @es_version ||= Gem::Version.new(Services.elasticsearch.info.dig("version", "number"))
    end
  end
end
