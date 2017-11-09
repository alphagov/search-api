module Debug
  module Synonyms
    class OldModel
      attr_reader :client
      attr_reader :index

      def initialize(index: "govuk", client: Services.elasticsearch)
        @client = client
        @index = index
      end

      def search(query)
        search_query = {
          query: {
            multi_match: {
              "query" => query,
              "fields" => %w(title^1000 description)
            }
          },
          highlight: {
            "fields" => { "title" => {}, "description" => {} },
            "pre_tags" => ["\e[32m"],
            "post_tags" => ["\e[0m"]
          }
        }

        client.search(index: index, analyzer: 'query_with_old_synonyms', body: search_query)
      end

      def analyze(query)
        client.indices.analyze text: query, analyzer: 'query_with_old_synonyms', index: index
      end
    end

    class NewModel
      attr_reader :client
      attr_reader :index

      def initialize(index: "govuk", client: Services.elasticsearch)
        @client = client
        @index = index
      end

      def search(query)
        search_query = {
          query: {
            multi_match: {
              "query" => query,
              "fields" => %w(title.synonym^1000 description.synonym)
            }
          },
          highlight: {
            "fields" => { "title.synonym" => {}, "description.synonym" => {} },
            "pre_tags" => ["\e[32m"],
            "post_tags" => ["\e[0m"]
          }
        }

        client.search(index: index, analyzer: 'with_search_synonyms', body: search_query)
      end

      def analyze(query)
        index_tokens = client.indices.analyze text: query, analyzer: 'with_index_synonyms', index: index
        search_tokens = client.indices.analyze text: query, analyzer: 'with_search_synonyms', index: index
        [index_tokens, search_tokens]
      end
    end
  end
end
