module Search
  # FIXME: This is for advanced_search (legacy)
  # it should be separate
  class ResultSet
    attr_reader :total, :results

    # Initialise from a list of Document objects.
    def initialize(results, total = results.size)
      @results = results.dup.freeze
      @total = total
    end

    def self.from_elasticsearch(elasticsearch_types, elasticsearch_response)
      total = elasticsearch_response["hits"]["total"]
      results = elasticsearch_response["hits"]["hits"].map { |hit|
        document_from_hit(hit, elasticsearch_types)
      }.freeze

      ResultSet.new(results, total)
    end

    def self.document_from_hit(hit, elasticsearch_types)
      # Default to edition if a result doesn't have a type.
      # This should not happen if we are using the elasticsearch API
      # properly. However this class should only be used by the "advanced search" (deprecated)
      # and our tests for that are not very realistic.
      type = hit['_type'] || "edition"


      doc_type = elasticsearch_types[type]
      if doc_type.nil?
        raise "Unexpected elasticsearch type '#{type}'. Document types must be configured"
      end

      Document.new(
        field_definitions: doc_type.fields,
        id: hit['_id'],
        type: type,
        source_attributes: hit['_source'],
        score: hit['_score']
      )
    end
  end
end
