module Clusters
  class Cluster
    attr_reader :key, :schema_config_file, :default

    def initialize(key:, uri_key:, schema_config_file: "opensearch_schema.yml", default: false)
      @key = key
      @uri_key = uri_key
      @schema_config_file = schema_config_file
      @default = default
    end

    def uri
      @uri ||= OpenSearchConfig.new.config[uri_key]
    end

    def inactive?
      # When a cluster URI is not active in an environment, we don't
      # define the config uri.
      uri.nil?
    end

  private

    attr_reader :uri_key
  end
end
