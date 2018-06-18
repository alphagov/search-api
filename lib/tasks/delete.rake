require 'rummager'

namespace :delete do
  desc "
  Delete a single content search result
  Usage
  LINK=/path/of/result rake delete:result
  "
  task :result do
    link = ENV.fetch("LINK")

    index = SearchConfig.instance.content_index
    raw_result = index.get_document_by_link(link)

    raise "No document found with link #{link}." unless raw_result

    index = search_server.index(raw_result['real_index_name'])
    index.delete(raw_result['_type'], raw_result['_id'])
  end

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

    links = DuplicateLinksFinder.new.find_exact_duplicates

    puts "Found #{links.size} duplicate links to delete"

    deleter = DuplicateDeleter.new(type_to_delete)
    deleter.call(links, id_type: 'link')
  end

  desc "
  Delete all documents by format from an index.
  Usage
  rake 'delete:by_format[format_name, elasticsearch_index]'
  "
  task :by_format, [:format, :index_name] do |_, args|
    format = args[:format]
    index  = args[:index_name]

    if format.nil?
      puts 'Specify format for deletion'
    elsif index.nil?
      puts 'Specify an index'
    else
      client = Services.elasticsearch(hosts: SearchConfig.new.base_uri, timeout: 5.0)

      delete_commands = ScrollEnumerator.new(
        client: client,
        search_body: { query: { term: { format: format } } },
        batch_size: 500,
        index_names: index
      ) { |hit| hit }.map do |hit|
        {
          delete: {
            _index: index,
            _type: hit['_type'],
            _id: hit['_id']
          }
        }
      end

      if delete_commands.empty?
        puts "No #{format} documents to delete"
      else
        puts "Deleting #{delete_commands.count} #{format} documents from #{index} index (in batches of 1000)"
        delete_commands.each_slice(1000) do |slice|
          client.bulk(body: slice)
        end

        client.indices.refresh(index: index)
      end
    end
  end
end
