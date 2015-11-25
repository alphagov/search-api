require PROJECT_ROOT + "/lib/taxonomy_prototype/data_downloader"

namespace :taxonomy_prototype do
  task :download_data do
    TaxonomyPrototype::DataDownloader.new.download
  end
end
