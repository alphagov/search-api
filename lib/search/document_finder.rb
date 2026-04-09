module Search
  class DocumentFinder
    TIMEOUT = 60

    def get_all_document_ids(index)
      response = Services.elasticsearch(timeout: TIMEOUT).search(
        index: index,
        size: 0, # temp figure - to be replaced
        body: {
          _source: %w[content_id],
          query: {
            match_all: {},
          },
        },
      )

      document_ids = []

      documents = response.dig("hits", "hits")

      documents.each do |document|
        document_ids << document["_source"]["content_id"]
      end
    end
  end
end
