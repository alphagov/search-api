module MetasearchIndex
  module Deleter
    class V2
      def initialize(id:)
        @id = id.presence || raise(ArgumentError, "ID must be supplied.")
      end

      def delete
        processor = Index::ElasticsearchProcessor.metasearch
        processor.delete(self)
        responses = processor.commit
        responses.each do |response|
          Index::ResponseValidator.new(namespace: "metasearch_index").valid!(response["items"].first)
        end
      end

      def identifier
        {
          _type: "generic-document",
          _id: @id,
        }
      end
    end
  end
end
