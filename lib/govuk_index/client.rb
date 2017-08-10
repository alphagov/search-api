module GovukIndex
  class Client
    TIMEOUT_SECONDS = 5.0

    class << self
      delegate :get, :bulk, to: :instance

      def instance
        @instance || new
      end
    end

    def get(params)
      client.get(
        params.merge(index: index_name)
      )
    end

    def bulk(params)
      client.bulk(
        params.merge(index: index_name)
      )
    end

  private

    def client(options = {})
      @_client ||= Services.elasticsearch(
        hosts: search_config.base_uri,
        timeout: options[:timeout] || TIMEOUT_SECONDS
      )
    end

    def search_config
      @_config ||= SearchConfig.instance
    end

    def index_name
      @_index ||= search_config.govuk_index_name
    end
  end
end
