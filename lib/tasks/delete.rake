namespace :delete do
  CONTENT_SEARCH_INDICES = %w(mainstream detailed government).freeze

  desc "
  Delete duplicates with the content IDs and/or links provided
  Usage
  TYPE_TO_DELETE=edition CONTENT_IDS=id1,id2 rake delete:duplicates
  TYPE_TO_DELETE=edition LINKS=/path/one,/path/two rake delete:duplicates
  "
  task :duplicates do
    require 'duplicate_deleter'

    type_to_delete = ENV.fetch("TYPE_TO_DELETE")
    content_ids = ENV.fetch('CONTENT_IDS', '').split(',').map(&:strip).compact
    links = ENV.fetch('LINKS', '').split(',').map(&:strip).compact

    deleter = DuplicateDeleter.new(type_to_delete)
    deleter.call(content_ids) if content_ids.any?
    deleter.call(links, id_type: 'link') if links.any?
  end

  desc "
  Find all duplicates and delete them
  Usage
  TYPE_TO_DELETE=edition rake delete:all_duplicates
  "
  task :all_duplicates do
    require 'duplicate_deleter'
    require 'duplicate_links_finder'

    type_to_delete = ENV.fetch("TYPE_TO_DELETE")

    elasticsearch_config = SearchConfig.new.elasticsearch

    links = DuplicateLinksFinder.new(elasticsearch_config["base_uri"], CONTENT_SEARCH_INDICES).find

    puts "Found #{links.size} duplicate links to delete"

    deleter = DuplicateDeleter.new(type_to_delete)
    deleter.call(links, id_type: 'link')
  end

  # Can be removed once run in production
  desc "Delete old business support scheme items"
  task :old_business_support do
    require "indexer/workers/delete_worker"
    elasticsearch_host = SearchConfig.new.elasticsearch["base_uri"]

    params = {
      query: { match_all: {} },
      filter: {
        bool: {
          must: {
            terms: { format: ["business_support"] }
          }
        }
      },
      size: 10_000
    }

    client = Elasticsearch::Client.new(host: elasticsearch_host)
    results = client.search(index: 'mainstream', body: params)

    puts "About to delete #{results['hits']['hits'].count} items"
    results['hits']['hits'].each_with_index do |item, i|
      puts "Deleting #{item['_id']} - (#{i + 1}/#{results['hits']['hits'].count}}"
      Indexer::DeleteWorker.perform_async('mainstream', item['_type'], item['_id'])
    end
  end
end
