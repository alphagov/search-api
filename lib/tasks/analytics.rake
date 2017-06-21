require "analytics_data"
require "csv"

namespace :analytics do
  desc "
  Export all indexed pages to a CSV suitable for importing into Google Analytics.

  The generated file is saved to disk, so you should run this task from the server and
  then use SCP to retrieve the file, which will be around 100 MB.
  "
  task :create_data_import_csv do
    elasticsearch_config = SearchConfig.new.elasticsearch

    analytics_data = AnalyticsData.new(elasticsearch_config["base_uri"], CONTENT_SEARCH_INDICES)

    CSV.open("data/analytics_data_import.csv", "wb") do |csv|
      csv << analytics_data.headers

      analytics_data.rows.each do |row|
        csv << row
      end
    end
  end
end
