class ResultSet

  attr_reader :total, :results

  def initialize(mappings, elasticsearch_response)
    @mappings = mappings
    @total = elasticsearch_response["hits"]["total"]
    @results = elasticsearch_response["hits"]["hits"].map { |hit|
      document_from_hit(hit)
    }.freeze
  end

private
  def document_from_hit(hit)
    hash = hit["_source"].merge(
      "es_score" => hit["_score"],
      "explanation" => hit["_explanation"]
    )
    Document.from_hash(hash, @mappings)
  end
end
