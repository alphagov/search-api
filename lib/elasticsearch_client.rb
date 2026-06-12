class ElasticsearchClient
  class << self
    private :new

    def instance
      Cache.get("#{ElasticsearchClient}") do
        new
      end
    end
  end

  def compatible_mappings(properties)
    return { "properties" => properties } if es7?

    { "generic-document" => { "properties" => properties } }
  end

private

  def es_version
    @es_version ||= Gem::Version.new(Services.elasticsearch.info.dig('version', 'number'))
  end

  def es7?
    return true if ENV["USE_ELASTICSEARCH_7"]
    return false if ENV["USE_ELASTICSEARCH_6"]
    es_version >= Gem::Version.new('7.0.0')
  end
end