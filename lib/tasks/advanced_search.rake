require "publishing_api_finder_publisher"

namespace :publishing_api do
  desc "Publish advanced-search finder."
  task :publish_advanced_search_finder do
    finder = YAML.load_file("config/advanced-search.yml")
    timestamp = Time.now.iso8601

    PublishingApiFinderPublisher.new(finder, timestamp).call
  end
end
