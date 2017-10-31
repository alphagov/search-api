require 'rummager'
require 'pp'

namespace :debug do
  desc "Pretty print a document in the old content indexes"
  task :show_old_index_link, [:link] do |_, args|
    index = SearchConfig.instance.old_content_index
    docs = index.get_document_by_link(args.link)
    pp docs
  end

  desc "Pretty print a document in the new content index"
  task :show_govuk_link, [:link] do |_, args|
    index = SearchConfig.instance.new_content_index
    docs = index.get_document_by_link(args.link)
    pp docs
  end
end
