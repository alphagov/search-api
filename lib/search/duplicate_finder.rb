module Search
  class DuplicateFinder
    TIMEOUT = 60

    attr_reader :index

    def initialize(index:)
      @index = index
    end

    def find_duplicates
      response = Services.elasticsearch(timeout: TIMEOUT).search(
        index: index,
        size: 0,
        body: {
          aggs: {
            dupes: {
              terms: {
                field: "content_id",
                size: 100_000,
                min_doc_count: 2,
              },
              aggs: {
                docs: {
                  top_hits: {
                    _source: %w[content_id title link updated_at],
                    size: 100,
                  },
                },
              },
            },
          },
        },
      )

      buckets = response.dig("aggregations", "dupes", "buckets") || []
      buckets.map do |bucket|
        hits = bucket.dig("docs", "hits", "hits") || []
        {
          content_id: bucket["key"],
          documents: hits.map { |hit| hit["_source"].slice("title", "link", "updated_at") },
        }
      end
    end
  end
end
