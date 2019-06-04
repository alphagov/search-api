module Clusters
  class Cluster
    attr_reader :key, :default

    def initialize(key:, uri_key:, default: false)
      @key = key
      @uri_key = uri_key
      @default = default
    end

    def uri
      @uri ||= elasticsearch_config[uri_key]
    end

    def inactive?
      # When a cluster URI is not active in an environment, we don't
      # define the config uri.
      uri.nil?
    end

  private

    attr_reader :uri_key

    def elasticsearch_config
      @elasticsearch_config ||= ElasticsearchConfig.new.config
    end
  end
end
