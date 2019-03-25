require "publishing_api_finder_publisher"
require "prepare_eu_exit_finder_publisher"

namespace :publishing_api do
  desc "Publish special routes such as sitemaps"
  task :publish_special_routes do
    publisher = SpecialRoutePublisher.new(
      logger: Logger.new(STDOUT),
      publishing_api: Services.publishing_api
    )

    begin
      publisher.take_ownership_of_search_routes
    rescue GdsApi::TimedOutException => e
      puts "WARNING: publishing-api timed out when trying to take ownership of a search route"
    rescue GdsApi::HTTPServerError => e
      puts "WARNING: publishing-api errored out when trying to take ownership of a search route \n\nError: #{e.inspect}"
    end

    publisher.routes.each do |route|
      begin
        publisher.publish(route)
      rescue GdsApi::TimedOutException
        puts "WARNING: publishing-api timed out when trying to publish route #{route[:base_path]}"
      rescue GdsApi::HTTPServerError => e
        puts "WARNING: publishing-api errored out when trying to publish route #{route[:base_path]}\n\nError: #{e.inspect}"
      end
    end
  end

  desc "Unpublish special routes"
  task :unpublish_prepare_business_and_uk_nationals_special_routes do
    content_ids = ["7a99da17-e9e1-410b-b67d-c3f6348c595d", "b9ef4434-761f-49ae-af97-dc7a248499c4"]
    content_ids.each do |content_id|
      Services.publishing_api.unpublish(content_id, type: "gone")
    end
  end

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

  desc "
    Publish finder and email signup content items

    Usage:
    FINDER_CONFIG=news_and_communications.yml EMAIL_SIGNUP_CONFIG=news_and_communications_email_signup.yml rake publishing_api:publish_finder
  "
  task :publish_finder do
    finder_config = ENV["FINDER_CONFIG"]
    email_signup_config = ENV["EMAIL_SIGNUP_CONFIG"]

    unless finder_config || email_signup_config
      raise "Please supply a valid config file name, e.g. FINDER_CONFIG=news_and_communications.yml and/or EMAIL_SIGNUP_CONFIG=news_and_communications_email_signup.yml"
    end

    timestamp = Time.now.iso8601

    unless email_signup_config.nil?
      email_signup = YAML.load_file("config/finders/#{email_signup_config}")
      ContentItemPublisher::FinderEmailSignupPublisher.new(email_signup, timestamp).call
    end

    unless finder_config.nil?
      finder = YAML.load_file("config/finders/#{finder_config}")
      ContentItemPublisher::FinderPublisher.new(finder, timestamp).call
    end
    puts "FINISHED"
  end

  desc "Publishes supergroup finders and their email signup pages"
  task :publish_supergroup_finders do
    finders = [
      {
        finder: 'all_content.yml',
        email_signup: 'all_content_email_signup.yml'
      },
      {
        finder: 'news_and_communications.yml',
        email_signup: 'news_and_communications_email_signup.yml'
      },
      {
        finder: 'guidance_and_regulation.yml',
        email_signup: 'guidance_and_regulation_email_signup.yml'
      },
      {
        finder: 'policy_and_engagement.yml',
        email_signup: 'policy_and_engagement_email_signup.yml'
      },
      {
        finder: 'statistics.yml',
        email_signup: 'statistics_email_signup.yml'
      },
      {
        finder: 'transparency.yml',
        email_signup: 'transparency_email_signup.yml'
      },
      {
        finder: 'services.yml',
      },
    ]

    puts "PUBLISHING ALL SUPERGROUP FINDERS..."

    finders.each { |finder_hash|
      finder_config = finder_hash[:finder]
      email_signup_config = finder_hash[:email_signup]
      timestamp = Time.now.iso8601

      puts "Publishing #{finder_config}..."

      unless email_signup_config.nil?
        email_signup = YAML.load_file("config/finders/#{email_signup_config}")
        ContentItemPublisher::FinderEmailSignupPublisher.new(email_signup, timestamp).call
      end

      unless finder_config.nil?
        finder = YAML.load_file("config/finders/#{finder_config}")
        ContentItemPublisher::FinderPublisher.new(finder, timestamp).call
      end
    }
    puts "FINISHED"
  end

  desc "
    Publish business readiness finder and email signup content items

    Usage:
    rake publishing_api:publish_eu_exit_business_finder
  "
  task :publish_eu_exit_business_finder do
    finder_config = File.join(Dir.pwd, "config", "find-eu-exit-guidance-business-email-signup.yml")
    email_signup_config = File.join(Dir.pwd, "config", "find-eu-exit-guidance-business.yml")

    timestamp = Time.now.iso8601

    unless email_signup_config.nil?
      email_signup = YAML.load_file(email_signup_config.to_s)
      ContentItemPublisher::FinderEmailSignupPublisher.new(email_signup, timestamp).call
    end

    unless finder_config.nil?
      finder = YAML.load_file(finder_config.to_s)
      ContentItemPublisher::FinderPublisher.new(finder, timestamp).call
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

    Services.publishing_api.unpublish(finder["content_id"], "gone")
    Services.publishing_api.unpublish(finder["signup_content_id"], "gone")
  end

  desc "Publish Prepare EU Exit finders"
  task :publish_prepare_eu_exit_finders do
    config = YAML.safe_load(ERB.new(File.read("config/prepare-eu-exit.yml.erb")).result_with_hash(config: {}))

    PrepareEuExitFinderPublisher.new(config["topics"], Time.now.iso8601).call
  end

  desc "Unpublish Prepare EU Exit finders"
  task :unpublish_prepare_eu_exit_finders do
    config = YAML.safe_load(ERB.new(File.read("config/prepare-eu-exit.yml.erb")).result_with_hash(config: {}))

    config["topics"].each do |topic|
      puts "Unpublishing #{topic['slug']}"
      Services.publishing_api.unpublish(topic["finder_content_id"], type: "gone")
    end
    puts "Finished"
  end
end
