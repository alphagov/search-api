require "gds_api/rummager"
require "gds_api/publishing_api_v2"
require "missing_metadata_fetcher"

PAGE_SIZE = 1000
MAX_PAGES = 52

desc "Fetch missing document metadata from the publishing api"
task :populate_metadata do
  rummager = GdsApi::Rummager.new(Plek.new.find("rummager"))
  publishing_api = GdsApi::PublishingApiV2.new(Plek.new.find("publishing-api"))
  fetcher = MissingMetadataFetcher.new(publishing_api)

  results = []

  0.upto MAX_PAGES do |page|
    puts "Fetching page #{page + 1}"

    response = rummager.search({
      "filter_content_store_document_type" => "_MISSING",
      "count" => PAGE_SIZE,
      "start" => page * PAGE_SIZE,
      "fields" => "content_id"
    })

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
    puts "Updating #{i}/#{total}"

    begin
      fetcher.add_metadata(result)
    rescue GdsApi::TimedOutException
      puts "Publishing API timed out... retrying"
      sleep(1)
      redo
    rescue StandardError
      puts "Skipped result #{result["elasticsearch_type"]}/#{result["_id"]}: #{$!}"
    end
  end
end
