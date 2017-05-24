namespace :delete do
  desc "Delete duplicates from index"
  task :duplicates do
    require 'duplicate_deleter'

    type_to_delete = ENV.fetch("TYPE_TO_DELETE")
    content_ids = ENV.fetch('CONTENT_IDS', '').split(',').map(&:strip).compact
    links = ENV.fetch('LINKS', '').split(',').map(&:strip).compact

    deleter = DuplicateDeleter.new(type_to_delete)
    deleter.call(content_ids) if content_ids.any?
    deleter.call(links, id_type: 'link') if links.any?
  end
end
