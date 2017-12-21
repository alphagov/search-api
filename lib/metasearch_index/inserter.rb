module MetasearchIndex
  module Inserter
    class V2
      def initialize(id:, document:)
        @id = id.presence || raise(ArgumentError, "ID must be supplied.")
        @document = document.presence || raise(ArgumentError, "No record provided to insert into Elasticsearch.")
      end

      def insert
        processor = Index::ElasticsearchProcessor.metasearch
        processor.save(self)
        response = processor.commit
        Index::ResponseValidator.new(namespace: 'metasearch_index').valid!(response["items"].first)
      end

      def identifier
        {
          _type: 'best_bet',
          _id: @id,
        }
      end

      def document
        {
          exact_query: @document["exact_query"],
          stemmed_query: @document["stemmed_query"],
          stemmed_query_as_term: @document["stemmed_query_as_term"],
          details: @document["details"],
        }
      end
    end
  end
end
