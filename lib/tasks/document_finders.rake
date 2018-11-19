require "publishing_api_finder_publisher"

namespace :publishing_api do
  desc "Publish document finder."
  task :publish_document_finder do
    document_finder_config = ENV["DOCUMENT_FINDER_CONFIG"]

    unless document_finder_config
      raise "Please supply a valid finder config file name"
    end

    finder = YAML.load_file("config/#{document_finder_config}")
    timestamp = Time.now.iso8601

    PublishingApiFinderPublisher.new(finder, timestamp).call
  end
end
