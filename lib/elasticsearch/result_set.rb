class ResultSet

  attr_reader :total, :results

  # Initialise from a list of Document objects.
  def initialize(results, total = results.size)
    @results = results.dup.freeze
    @total = total
  end

  def self.from_elasticsearch(document_types, elasticsearch_response)
    total = elasticsearch_response["hits"]["total"]
    results = elasticsearch_response["hits"]["hits"].map { |hit|
      document_from_hit(hit, document_types)
    }.freeze

    ResultSet.new(results, total)
  end

private
  def self.document_from_hit(hit, document_types)
    Document.from_hash(hit["_source"], document_types, hit["_score"])
  end
end
