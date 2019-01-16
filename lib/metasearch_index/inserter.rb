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
          stemmed_query_as_term: @document["stemmed_query"].presence && " #{analyzed_stemmed_query} ",
          details: @document["details"],
        }
      end

      def analyzed_stemmed_query
        analyzed_query = MetasearchIndex::Client.analyze(
          text: @document["stemmed_query"],
          analyzer: "best_bet_stemmed_match",
        )
        analyzed_query["tokens"].map { |token_info| token_info["token"] }.join(" ")
      end
    end
  end
end
