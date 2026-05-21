require "rummager"
desc "Delete the detailed index"
task :delete_government_index do
  client = Services.elasticsearch

  indices = client.indices.get_alias(name: "government").keys

  puts "Deleting indices: #{indices.join(', ')}"

  client.indices.delete(index: indices)
rescue Elasticsearch::Transport::Transport::Errors::NotFound
  puts "No detailed index found"
end
