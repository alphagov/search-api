require "rummager"
require_relative "./task_helper"

namespace :delete do
  desc "
  Delete a document from the govuk index by link
  Usage
  rake 'delete:by_link[link]'"
  task :by_link, [:link] do |_, args|
    id = args[:link]
    abort "Missing argument. Usage: rake 'delete:by_link[link]'" if args[:link].nil?

    Services.elasticsearch.delete(index: SearchConfig.govuk_index_name, type: "generic-document", id:)
  end

  desc "
  Delete all documents by format from an index.
  Usage
  rake 'delete:by_format[format_name, elasticsearch_index]'
  "
  task :by_format, [:format, :index_name] do |_, args|
    format = args[:format]
    index  = args[:index_name]

    abort "Specify format for deletion" if format.nil?
    abort "Specify an index" if index.nil?

    warn_for_single_cluster_run
    client = Services.elasticsearch(cluster: Clusters.default_cluster, timeout: 5.0)

    delete_commands = ScrollEnumerator.new(
      client:,
      search_body: { query: { term: { format: } } },
      batch_size: 500,
      index_names: index,
    ) { |hit| hit }.map do |hit|
      {
        delete: {
          _index: index,
          _type: hit["_type"],
          _id: hit["_id"],
        },
      }
    end

    if delete_commands.empty?
      puts "No #{format} documents to delete"
    else
      puts "Deleting #{delete_commands.count} #{format} documents from #{index} index (in batches of 1000)"
      delete_commands.each_slice(1000) do |slice|
        client.bulk(body: slice)
      end

      client.indices.refresh(index:)
    end
  end
end
