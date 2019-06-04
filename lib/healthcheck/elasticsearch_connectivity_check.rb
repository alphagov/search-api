require 'govuk_app_config'

module Healthcheck
  # This is a custom check that is called by GovukHealthcheck
  # See GovukHealthcheck (govuk_app_config/docs/healthchecks.md) for usage info
  class ElasticsearchConnectivityCheck
    def name
      :elasticsearch_connectivity
    end

    def status
      can_connect? ? :ok : :critical
    end

    def message
      if can_connect?
        "search-api can to connect to elasticsearch"
      else
        "search-api CANNOT connect to elasticsearch!"
      end
    end

    def details
      can_connect? ? { extra: cluster_health } : {}
    end

    # Optional
    def enabled?
      true # false if the check is not relevant at this time
    end

  private

    def can_connect?
      cluster_health.present?
    rescue Faraday::Error
      false
    end

    def cluster_health
      # Makes a call to the elasticsearch cluster
      @cluster_health ||= elasticsearch_client.cluster.health
    end

    def elasticsearch_url
      SearchConfig.instance.base_uri
    end

    def elasticsearch_client
      # TODO: healthcheck all active clusters
      @elasticsearch_client ||= Services::elasticsearch(hosts: elasticsearch_url)
    end
  end
end
