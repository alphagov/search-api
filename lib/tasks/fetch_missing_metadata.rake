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

  0.upto MAX_PAGES do |page|
    response = rummager.search({
      "filter_content_store_document_type" => "_MISSING",
      "count" => PAGE_SIZE,
      "start" => page * PAGE_SIZE,
      "fields" => "content_id"
    })

    puts "page #{page + 1} (#{response["total"]} total results)"

    response["results"].each_with_index do |result, _i|
      if result["_id"].start_with?("https://", "http://")
        puts "Skipping #{result["elasticsearch_type"]}/#{result["_id"]}"
        next
      end

      begin
        fetcher.add_metadata(result)
      rescue GdsApi::TimedOutException
        puts "Publishing API timed out... retrying"
        sleep(1)
        redo
      rescue StandardError => e
        puts "Skipped result #{result["elasticsearch_type"]}/#{result["_id"]}: #{$!}\n#{e.backtrace.join("\n")}"
      end
    end
  end
end
