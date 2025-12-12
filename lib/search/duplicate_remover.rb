module Search
  class DuplicateRemover
    attr_reader :index, :logger

    def initialize(index:, logger: Logger.new($stdout))
      @index = index
      @logger = logger
    end

    def remove_duplicates(duplicates:)
      duplicates.each do |duplicate|
        if duplicate[:documents].all? { |doc| doc["updated_at"].nil? }
          logger.info "None of the documents with content_item: #{duplicate[:content_id]} have an 'updated_at' field."
          next
        end

        sorted_docs = sort_by_updated_at(duplicate[:documents])

        # Delete all duplicate documents except the most recent one.
        sorted_docs.drop(1).each do |doc|
          delete_document(doc["link"])
        end
      end
    end

  private

    # Sorts documents in descending order by 'updated_at' field.
    # If updated_at is nil or it is not defined, it puts the document at the end of the list.
    def sort_by_updated_at(documents)
      documents.sort do |doc1, doc2|
        next 0 if doc1["updated_at"] == doc2["updated_at"]
        next 1 if doc1["updated_at"].nil?
        next -1 if doc2["updated_at"].nil?

        doc2["updated_at"] <=> doc1["updated_at"]
      end
    end

    def delete_document(link)
      Services.elasticsearch.delete_by_query(
        index: index,
        body: { query: { term: { link: link } } },
      )
      logger.info "Deleted duplicate document: #{link}"
    end
  end
end
