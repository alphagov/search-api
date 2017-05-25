require_relative "../app"

class DuplicateLinksFinder
  def initialize(elasticsearch_url, indices)
    @elasticsearch_url = elasticsearch_url
    @indices = indices
  end

  def find
    client = Elasticsearch::Client.new(host: elasticsearch_url)

    body = {
      "query": {
        "match_all": {}
      },
      "aggs": {
        "duplicates": {
          "terms": {
            "field": "link",
            "order": {
              "_count": "desc"
            },
            "size": 100000,
            "min_doc_count": 2
          }
        }
      }
    }

    results = client.search(index: indices, body: body)
    results["aggregations"]["duplicates"]["buckets"].map { |duplicate| duplicate["key"] }
  end

private

  attr_reader :elasticsearch_url, :indices
end
