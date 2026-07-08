require "govuk_app_config"

module Healthcheck
  # This is a custom check that is called by GovukHealthcheck
  # See GovukHealthcheck (govuk_app_config/docs/healthchecks.md) for usage info
  class OpenSearchConnectivityCheck
    def name
      :opensearch_connectivity
    end

    def status
      clusters_healthy? ? :ok : :critical
    end

    def message
      if clusters_healthy?
        "search-api can connect to all opensearch clusters"
      else
        names = failing_clusters.map(&:key).join(", ")
        failed = failing_clusters.count
        "search-api cannot connect to #{failed} opensearch #{'cluster'.pluralize(failed)}! \n Failing: #{names}"
      end
    end

    def details
      clusters_healthy? ? { extra: cluster_healths } : {}
    end

    # Optional
    def enabled?
      true # false if the check is not relevant at this time
    end

  private

    def clusters_healthy?
      @clusters_healthy ||= failing_clusters.none?
    end

    def failing_clusters
      @failing_clusters ||= Clusters.active.reject { |cluster| can_connect?(cluster) }
    end

    def can_connect?(cluster)
      cluster_health(cluster).present?
    rescue Faraday::Error
      false
    end

    def cluster_healths
      {
        cluster_healths: Clusters.active.map do |cluster|
          cluster_health(cluster).merge(cluster_name: cluster.key)
        end,
      }
    end

    def cluster_health(cluster)
      # Makes a call to the opensearch cluster
      opensearch_client(cluster).cluster.health
    end

    def opensearch_client(cluster)
      Services.opensearch(cluster:)
    end
  end
end
