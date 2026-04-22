require "rummager"

namespace :duplicates do
  desc "Find all documents with the same content_id"
  task :find do
    index = SearchConfig.govuk_index_name

    duplicates = Search::DuplicateFinder.new(index:).find_duplicates

    duplicates.each do |duplicate|
      puts "Content_id: #{duplicate[:content_id]}"
      duplicate[:documents].each do |doc|
        puts "  #{doc['title']} #{doc['link']} #{doc.fetch('updated_at', '')}"
      end
    end
  end

  desc "Find all documents with the same content_id and remove them"
  task :remove do
    index = SearchConfig.govuk_index_name

    duplicates = Search::DuplicateFinder.new(index:).find_duplicates
    puts "No duplicates found" if duplicates.empty?

    Search::DuplicateRemover.new(index:).remove_duplicates(duplicates: duplicates)
  end
end
