require 'rummager'

desc "Destroy metadata for all eu exit guidance"
task :destroy_metadata_for_eu_exit_guidance do
  Indexer::MetadataTagger.destroy_all_eu_exit_guidance!
end
