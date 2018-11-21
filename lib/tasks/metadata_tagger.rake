require 'rummager'

desc "Apply metadata from the json file"
task :tag_metadata do
  Indexer::MetadataTagger.amend_indexes_for_file(file_path)
end
