module Search
  # This is only used by Advanced Search
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
      Document.from_hash(
        hit["_source"].merge("_id" => hit["_id"]),
        elasticsearch_types,
        hit["_score"])
    end
  end
end
