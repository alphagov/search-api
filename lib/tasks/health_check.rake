require 'health_check/logging_config'
require 'health_check/checker'
require 'health_check/downloader'

DATA_DIR = File.dirname(__FILE__) + "/../../data/"

namespace :health_check do
  desc "Downloads checks to run from Google Docs. Optionally specify indices in INDICES environment variable."
  task :download do
    FileUtils.mkdir_p(DATA_DIR)
    HealthCheck::Downloader.new(data_dir: DATA_DIR).download(*%w{mainstream detailed government})
  end

  desc "run health checks"
  task :run do
    test_data = DATA_DIR + "government-weighted-search-terms.csv"
    index_name = "government"
    result = HealthCheck::Checker.new(index: index_name, test_data: test_data).run!
    result.summarise("#{index_name.capitalize} score")
  end
end