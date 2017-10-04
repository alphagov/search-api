module GovukIndex
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
      client.bulk(
        params.merge(index: index_name)
      )
    end

  private

    def client
      @_client ||= Services.elasticsearch(
        hosts: search_config.base_uri,
        timeout: @_options[:timeout] || TIMEOUT_SECONDS,
        retry_on_failure: true,
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
