module ElasticsearchClient
  class << self
    def es7?
      return true if ENV["USE_ELASTICSEARCH_7"]
      return false if ENV["USE_ELASTICSEARCH_6"]

      es_version >= Gem::Version.new("7.0.0")
    end

    def reload_version
      @es_version = nil
    end

  private

    def es_version
      @es_version ||= Gem::Version.new(Services.elasticsearch.info.dig("version", "number"))
    end
  end
end
