require 'rummager'

desc "Apply metadata from the json file"
task :tag_metadata do
  Indexer::MetadataTagger.amend_all_metadata
end

desc "Destroy metadata for a path"
task :destroy_metadata_for_base_paths, [:base_paths] do |_, args|
  USAGE_MESSAGE = "usage: rake destroy_metadata_for_base_paths[<base_paths>]".freeze
  abort USAGE_MESSAGE unless args[:base_paths]

  base_paths = args[:base_paths].split
  Indexer::MetadataTagger.remove_all_metadata_for_base_paths(base_paths)
end
