require "analytics/export_pages_to_google_analytics"
require "csv"

namespace :analytics do
  ALL_CONTENT_SEARCH_INDICES = %w[detailed government govuk].freeze

  desc "Export all indexed pages to Google Analytics"
  task :export_indexed_pages_to_google_analytics, :environment do
    warn_for_single_cluster_run

    begin
      puts "Starting page exporter"
      Analytics.export_pages_to_google_analytics
      puts "Indexed paged upload to Google Analytics has completed"
    rescue StandardError => e
      puts "Error while uploading data to Google Analytics:\n#{e}"
      raise e
    end
  end
end
