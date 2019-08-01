require 'analytics/export_pages_to_google_analytics'
require "analytics_data"
require "csv"

namespace :analytics do
  ALL_CONTENT_SEARCH_INDICES = %w(detailed government govuk).freeze

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

  desc "
  Export all indexed pages to a CSV suitable for importing into Google Analytics.

  The generated file is saved to disk, so you should run this task from the server and
  then use SCP to retrieve the file, which will be around 100 MB.
  "
  task :create_data_import_csv, [:path] do |_, args|
    warn_for_single_cluster_run
    args.with_defaults(path: (ENV['EXPORT_PATH'] || 'data'))
    path = args[:path]

    analytics_data = AnalyticsData.new(Clusters.default_cluster.uri, ALL_CONTENT_SEARCH_INDICES)

    FileUtils.mkdir_p(path)

    file_name = "#{path}/analytics_data_import_#{Date.today.strftime('%Y%m%d')}.csv"
    puts "Exporting to: #{file_name}"

    CSV.open(file_name, "wb") do |csv|
      csv << analytics_data.headers

      analytics_data.rows.each do |row|
        csv << row
      end
    end
  end

  desc "Delete old export files (specify the number to keep with EXPORT_FILE_LIMIT)"
  task :delete_old_files, [:path, :export_file_limit] do |_, args|
    args.with_defaults(path: (ENV['EXPORT_PATH'] || 'data'),
                       export_file_limit: (ENV['EXPORT_FILE_LIMIT'] || 10))
    path = args[:path]
    export_file_limit = args[:export_file_limit].to_i

    files = Dir["#{path}/analytics_data_import_*.csv"]
    files = files.sort
    files[0..-export_file_limit].each do |file|
      puts "Removing file: #{file}"
      File.delete(file)
    end
  end
end
