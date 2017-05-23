namespace :delete do
  desc "Delete duplicates from index"
  task :duplicates do
    require 'duplicate_deleter'

    type_to_delete = ENV.fetch("TYPE_TO_DELETE")
    content_ids = ENV.fetch('CONTENT_IDS').split(',').map(&:strip)

    DuplicateDeleter.new(type_to_delete).call(content_ids)
  end
end
