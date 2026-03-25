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
      @clusters = options.delete(:clusters) || Clusters.active
      @_options = options
    end

    def get(params)
      raise "does not accept _type" if params[:_type] || params["_type"]
      ElasticsearchClient.get_by_id(id: params[:id], index_name:, client:)
    end

    def bulk(params)
      clusters.map do |cluster|
        ElasticsearchClient.bulk(body: params[:body], index_name:, client: client(cluster:))
      end
    end

  private

    attr_reader :clusters

    def client(cluster: Clusters.default_cluster)
      @_client ||= {}
      @_client[cluster.key] ||= Services.elasticsearch(
        cluster:,
        timeout: @_options[:timeout] || TIMEOUT_SECONDS,
        retry_on_failure: true,
      )
    end

    def index_name
      raise "Must be implemented in child class"
    end
  end
end
