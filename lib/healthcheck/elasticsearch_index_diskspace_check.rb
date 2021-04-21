require "govuk_app_config"

module Healthcheck
  # This is a custom check that is called by GovukHealthcheck
  # See GovukHealthcheck (govuk_app_config/docs/healthchecks.md) for usage info
  class ElasticsearchIndexDiskspaceCheck
    def name
      :elasticsearch_diskspace
    end

    def status
      low_diskspace? ? :critical : :ok
    end

    def message
      if low_diskspace?
        "there is not enough diskspace for the elasticsearch indices! Consider running index cleanup rake task"
      else
        "there is enough diskspace for the elasticsearch indices"
      end
    end

    def details
      low_diskspace?
      { "extra" => "total free space remaining on nodes: #{percentage_free}%" }
    end

    # Optional
    def enabled?
      true # false if the check is not relevant at this time
    end

    def to_hash
      {
        status: status,
        message: message,
      }.merge(details)
    end

  private

    # Tune this to affect the amount of free space we need available as a minimum % before we alert
    LOW_SPACE_THRESHOLD = 20 # percent

    def cluster_stats
      @cluster_stats ||= begin
        client = Services.elasticsearch(cluster: Clusters.default_cluster)
        es_stats = client.perform_request "GET", "_nodes/stats/fs?pretty=true"
        es_stats.body["nodes"].each_with_object({ total: 0, avail: 0 }) do |(_, node_stat), hsh|
          hsh[:total] += node_stat.dig("fs", "total", "total_in_bytes")
          hsh[:avail] += node_stat.dig("fs", "total", "available_in_bytes")
        end
      end
    end

    def percentage_free
      cluster_stats[:avail] / (cluster_stats[:total] / 100)
    end

    def low_diskspace?
      percentage_free < LOW_SPACE_THRESHOLD
    end
  end
end
