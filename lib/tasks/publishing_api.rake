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
end
