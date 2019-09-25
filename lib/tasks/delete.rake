require "rummager"

namespace :delete do
  desc "
  Delete all documents by format from an index.
  Usage
  rake 'delete:by_format[format_name, elasticsearch_index]'
  "
  task :by_format, [:format, :index_name] do |_, args|
    format = args[:format]
    index  = args[:index_name]

    if format.nil?
      puts "Specify format for deletion"
    elsif index.nil?
      puts "Specify an index"
    else
      warn_for_single_cluster_run
      client = Services.elasticsearch(cluster: Clusters.default_cluster, timeout: 5.0)

      delete_commands = ScrollEnumerator.new(
        client: client,
        search_body: { query: { term: { format: format } } },
        batch_size: 500,
        index_names: index
      ) { |hit| hit }.map do |hit|
        {
          delete: {
            _index: index,
            _type: hit["_type"],
            _id: hit["_id"]
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
