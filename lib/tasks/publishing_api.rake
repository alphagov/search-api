require "publishing_api_finder_publisher"

namespace :publishing_api do
  desc "
    Publish finder and email signup content items

    Usage:
    FINDER_CONFIG=news_and_communications_finder.yml EMAIL_SIGNUP_CONFIG=news_and_communications_email_signup.yml rake publishing_api:publish_finder
  "
  task :publish_finder do
    finder_config = ENV["FINDER_CONFIG"]
    email_signup_config = ENV["EMAIL_SIGNUP_CONFIG"]

    base_path = "config/finders/"
    timestamp = Time.now.iso8601

    unless finder_config || email_signup_config
      raise "Please supply a valid config file name, e.g. FINDER_CONFIG=news_and_communications.yml and/or EMAIL_SIGNUP_CONFIG=news_and_communications_email_signup.yml"
    end

    ContentItemPublisher.publish(config: File.join(base_path, finder_config), timestamp:) unless finder_config.nil?
    ContentItemPublisher.publish(config: File.join(base_path, email_signup_config), timestamp:) unless email_signup_config.nil?

    puts "FINISHED"
  end

  desc "Publishes supergroup finders and their email signup pages"
  task :publish_supergroup_finders do
    puts "PUBLISHING ALL SUPERGROUP FINDERS..."
    timestamp = Time.now.iso8601
    Dir.glob("config/finders/*.yml").each do |config|
      ContentItemPublisher.publish(config:, timestamp:)
    end
    puts "FINISHED"
  end

  desc "Unpublish document finder."
  task :unpublish_document_finder do
    document_finder_config = ENV["DOCUMENT_FINDER_CONFIG"]

    unless document_finder_config
      raise "Please supply a valid finder config file name"
    end

    finder = YAML.load_file("config/#{document_finder_config}")

    Services.publishing_api.unpublish(finder["content_id"], type: "gone")
    Services.publishing_api.unpublish(finder["signup_content_id"], type: "gone")
  end
end
