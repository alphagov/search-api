module GovukIndex
  class ElasticsearchProcessor
    TIMEOUT_SECONDS = 5.0

    def initialize
      @actions = []
    end

    def save(presenter)
      @actions << { index: presenter.identifier }
      @actions << presenter.document
    end

    def delete(presenter)
      @actions << { delete: presenter.identifier }
    end

    def commit
      return if @actions.empty?
      client.bulk(
        index: index_name,
        body: @actions
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
