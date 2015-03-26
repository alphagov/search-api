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

  def weighted(factor)
    ResultSet.new(@results.map { |r| r.weighted(factor) }, @total)
  end

  def merge(other)
    merged_results = (@results + other.results).sort_by(&:es_score).reverse
    new_total = @total + other.total
    ResultSet.new(merged_results, new_total)
  end

  def take(count)
    ResultSet.new(@results.take(count), @total)
  end

  # Return a ResultSet of all the items in this set that aren't in the other
  # set. Equivalent in intent to Array#-.
  def -(other)
    # Using the link as the unique identifier; we can't simply test for
    # equality, because we may be comparing weighted and unweighted results,
    # which don't have the same attributes, so shouldn't be considered equal.
    links = results.map(&:link)
    other_links = other.results.map(&:link)
    common_count = (links & other_links).count

    ResultSet.new(results.reject { |r| other_links.include? r.link },
                  total - common_count)
  end

private
  def self.document_from_hit(hit, document_types)
    Document.from_hash(hit["_source"], document_types, hit["_score"])
  end
end
