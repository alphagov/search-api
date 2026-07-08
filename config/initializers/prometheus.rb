require "govuk_app_config/govuk_prometheus_exporter"
require_relative "../../lib/collectors/opensearch_prometheus_collector"

GovukPrometheusExporter.configure(collectors: [Collectors::OpenSearchPrometheusCollector])
