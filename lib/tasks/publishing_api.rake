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
