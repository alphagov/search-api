module GovukIndex
  class ElasticsearchSaver
    TIMEOUT_SECONDS = 5.0

    def save(presenter)
      client.bulk(
        index: index_name,
        body: [
          { index: presenter.identifier },
          presenter.document
        ]
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
      @_config ||= Rummager.search_config
    end

    def index_name
      @_index ||= search_config.govuk_index_name
    end
  end
end
