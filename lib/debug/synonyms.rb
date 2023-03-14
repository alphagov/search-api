module Debug
  module Synonyms
    class Analyzer
      attr_reader :client, :index

      def initialize(index: "govuk", client: Services.elasticsearch)
        @client = client
        @index = index
      end

      def search(query, pre_tags:, post_tags:)
        search_query = {
          query: {
            multi_match: {
              "query" => query,
              "fields" => %w[title.synonym^1000 description.synonym],
            },
          },
          highlight: {
            "fields" => { "title.synonym" => {}, "description.synonym" => {} },
            "pre_tags" => pre_tags,
            "post_tags" => post_tags,
          },
        }

        client.search(index:, analyzer: "with_search_synonyms", body: search_query)
      end

      def analyze_query(query)
        client.indices.analyze index:, body: { text: query, analyzer: "with_search_synonyms" }
      end

      def analyze_index(query)
        client.indices.analyze index:, body: { text: query, analyzer: "with_index_synonyms" }
      end
    end
  end
end
