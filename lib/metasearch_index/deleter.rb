module MetasearchIndex
  module Deleter
    class V2
      def initialize(id:)
        @id = id.presence || raise(ArgumentError, "ID must be supplied.")
      end

      def delete
        processor = Index::ElasticsearchProcessor.metasearch
        processor.delete(self)
        response = processor.commit
        Index::ResponseValidator.new(namespace: 'metasearch_index').valid!(response['items'].first)
      end

      def identifier
        {
          _type: 'generic-document',
          _id: @id,
        }
      end
    end
  end
end
