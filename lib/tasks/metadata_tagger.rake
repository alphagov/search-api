require 'rummager'

desc "Apply metadata from the json file"
task :tag_metadata do
  file_path = File.join(settings.root, '../../config/metadata.csv')
  Indexer::MetadataTagger.amend_indexes_for_file(file_path)
end
