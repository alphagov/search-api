require "prometheus_exporter"
require "prometheus_exporter/server"

module Collectors
  class ElasticsearchPrometheusCollector < PrometheusExporter::Server::TypeCollector
    def type
      "elasticsearch"
    end

    def metrics
      disk_space_gauge = PrometheusExporter::Metric::Gauge.new("search_api_elasticsearch_disk_space", "Percentage of available disk space for Elasticsearch")
      status_gauge = PrometheusExporter::Metric::Gauge.new("search_api_elasticsearch_status", "Status of the Elasticsearch cluster (red = 2, yellow = 1, green = 0)")

      free_disk_space_ratios.each do |node, space|
        disk_space_gauge.observe(space, node:)
      end
      status_gauge.observe(cluster_health)
      [disk_space_gauge, status_gauge]
    end

  private

    def free_disk_space_ratios
      nodes_stats_hash = Services.elasticsearch.nodes.stats(metric: "fs")

      nodes_stats_hash["nodes"].transform_values do |node|
        total = node.dig("fs", "total", "total_in_bytes")
        available = node.dig("fs", "total", "available_in_bytes")

        raise "Node stats invalid: #{nodes_stats_hash}" unless total&.positive?

        available.to_f / total
      end
    end

    def cluster_health
      status_string = Services.elasticsearch.cluster.health["status"]
      case status_string
      when "green"  then 0
      when "yellow" then 1
      when "red"    then 2
      else 3 # Can be 'unknown' or 'unavailable' in rare cases according to the docs:
        # https://www.elastic.co/docs/api/doc/elasticsearch/operation/operation-cluster-health
      end
    end
  end
end
