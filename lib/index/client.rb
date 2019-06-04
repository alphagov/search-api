module Index
  class Client
    TIMEOUT_SECONDS = 5.0

    class << self
      delegate :get, :bulk, to: :instance

      def instance
        @_instance || new
      end
    end

    def initialize(options = {})
      @_index = options.delete(:index_name)
      @_options = options
    end

    def get(params)
      client.get(
        params.merge(index: index_name)
      )
    end

    def bulk(params)
      Clusters.active.map do |cluster|
        client(cluster: cluster).bulk(
          params.merge(index: index_name)
        )
      end
    end

  private

    def client(cluster: Clusters.default_cluster)
      @_client ||= {}
      @_client[cluster.key] ||= Services.elasticsearch(
        cluster: cluster,
        timeout: @_options[:timeout] || TIMEOUT_SECONDS,
        retry_on_failure: true,
      )
    end

    def search_config
      @_config ||= SearchConfig.instance
    end

    def index_name
      raise "Must be implemented in child class"
    end
  end
end
