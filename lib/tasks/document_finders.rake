require "publishing_api_finder_publisher"
require "publishing_api_topic_finder_publisher"

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

  desc "Unpublish document finder."
  task :unpublish_document_finder do
    document_finder_config = ENV["DOCUMENT_FINDER_CONFIG"]

    unless document_finder_config
      raise "Please supply a valid finder config file name"
    end

    finder = YAML.load_file("config/#{document_finder_config}")

    Services.publishing_api.unpublish(finder["content_id"], "gone")
    Services.publishing_api.unpublish(finder["signup_content_id"], "gone")
  end

  desc "Publish citizen topic finders"
  task :publish_citizen_finders do
    topic_config = YAML.load_file("config/topic_finders/finder_content_items.yml")

    PublishingApiTopicFinderPublisher.new(topic_config["topics"], Time.now.iso8601).call
  end

  desc "Unpublish citizen topic finders"
  task :unpublish_citizen_finders do
    topic_config = YAML.load_file("config/topic_finders/finder_content_items.yml")

    topic_config["topics"].each do |topic|
      puts "Unpublishing #{topic['slug']}"
      Services.publishing_api.unpublish(topic["finder_content_id"], type: "gone")
    end
    puts "Finished"
  end
end
