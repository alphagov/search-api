module MetasearchIndex
  module Inserter
    class V2
      def initialize(id:, document:)
        @id = id.presence || raise(ArgumentError, "ID must be supplied.")
        @document = document.presence || raise(ArgumentError, "No record provided to insert into OpenSearch.")
      end

      def insert
        processor = Index::OpenSearchProcessor.metasearch
        processor.save(self)
        responses = processor.commit
        responses.each do |response|
          Index::ResponseValidator.new(namespace: "metasearch_index").valid!(response["items"].first)
        end
      end

      def identifier
        {
          _id: @id,
        }
      end

      def document
        {
          exact_query: @document["exact_query"],
          stemmed_query: @document["stemmed_query"],
          stemmed_query_as_term: @document["stemmed_query"].presence && " #{analyzed_stemmed_query} ",
          details: @document["details"],
          document_type: "best_bet",
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
