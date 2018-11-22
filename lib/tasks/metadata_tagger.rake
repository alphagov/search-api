require 'rummager'

desc "Apply metadata from the json file"
task :tag_metadata do
  Indexer::MetadataTagger.amend_all_metadata
end
