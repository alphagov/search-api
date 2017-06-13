require "gds_api/rummager"
require "gds_api/publishing_api_v2"
require "missing_metadata_fetcher"

desc "Fetch missing document metadata from the publishing api"
task :populate_metadata do
  PAGE_SIZE = 200
  MAX_PAGES = 52

  rummager = GdsApi::Rummager.new(Plek.new.find("rummager"))
  publishing_api = GdsApi::PublishingApiV2.new(Plek.new.find("publishing-api"))
  fetcher = MissingMetadataFetcher.new(publishing_api)

  missing_field_name = ENV.fetch('MISSING_FIELD', 'content_id')
  results = []

  (0..Float::INFINITY).lazy.each do |page|
    puts "Fetching page #{page + 1}"

    response = rummager.search({
      "filter_#{missing_field_name}" => "_MISSING",
      "count" => PAGE_SIZE,
      "start" => page * PAGE_SIZE,
      "fields" => "content_id"
    })

    break if response["results"].empty?

    response["results"].each do |result|
      if result["_id"].start_with?("https://", "http://")
        puts "Skipping #{result["elasticsearch_type"]}/#{result["_id"]}"
        next
      end

      results << result.slice("_id", "content_id", "index")
    end
  end

  total = results.size

  results.each_with_index do |result, i|
    puts "Updating #{i}/#{total}: #{result['_id']}"

    begin
      fetcher.add_metadata(result)
    rescue StandardError
      puts "Skipped result #{result["elasticsearch_type"]}/#{result["_id"]}: #{$!}"
    end
  end
end
