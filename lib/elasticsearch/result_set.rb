class ResultSet

  attr_reader :total, :results

  # Initialise from a list of Document objects.
  def initialize(results, total = results.size)
    @results = results.dup.freeze
    @total = total
  end

  def self.from_elasticsearch(mappings, elasticsearch_response)
    total = elasticsearch_response["hits"]["total"]
    results = elasticsearch_response["hits"]["hits"].map { |hit|
      document_from_hit(hit, mappings)
    }.freeze

    ResultSet.new(results, total)
  end

private
  def self.document_from_hit(hit, mappings)
    Document.from_hash(hit["_source"], mappings, hit["_score"])
  end
end
