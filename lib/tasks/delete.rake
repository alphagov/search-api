require 'rummager'

namespace :delete do
  CONTENT_SEARCH_INDICES = %w(mainstream detailed government).freeze

  desc "
  Delete duplicates with the content IDs and/or links provided
  Usage
  TYPE_TO_DELETE=edition CONTENT_IDS=id1,id2 rake delete:duplicates
  TYPE_TO_DELETE=edition LINKS=/path/one,/path/two rake delete:duplicates
  "
  task :duplicates do
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
    type_to_delete = ENV.fetch("TYPE_TO_DELETE")

    elasticsearch_config = SearchConfig.new.elasticsearch

    links = DuplicateLinksFinder.new(elasticsearch_config["base_uri"], CONTENT_SEARCH_INDICES).find_exact_duplicates

    puts "Found #{links.size} duplicate links to delete"

    deleter = DuplicateDeleter.new(type_to_delete)
    deleter.call(links, id_type: 'link')
  end

  desc "
  Delete the documents from a search index as specified in the given file. The
  file should contain a list of page paths separated by new lines.
  Usage
  rake 'delete:documents_from_file[/path/to/file, mainstream]'
  "
  task :documents_from_file, [:file_path, :index_name] do |_, args|
    search_config = SearchConfig.new
    index = search_config.search_server.index(args[:index_name])

    CSV.read(args[:file_path]).each do |row|
      base_path = row[0]

      search_result = index.get_document_by_id(base_path)

      if search_result
        puts "Deleting #{base_path}"
        Indexer::DeleteWorker.perform_async("mainstream", "dfid_research_output", base_path)
      else
        puts "Skipping #{base_path} because it is not present in the search index"
      end
    end
  end

  desc "
  Delete all documents by format from an index.
  Usage
  rake 'delete:by_format[format_name, elasticsearch_index]'
  "
  task :by_format, [:format, :index_name] do |_, args|
    if args[:format].nil?
      puts 'Specify format for deletion'
    else
      client = Services.elasticsearch(
        hosts: SearchConfig.new.base_uri,
        timeout: 5.0
      )

      puts "Deleting all #{args[:format]} documents from #{args[:index_name]} index"
      client.delete_by_query(
        index: args[:index_name],
        body: {
          query: { match: { format: args[:format] } }
        }
      )
    end
  end
end
