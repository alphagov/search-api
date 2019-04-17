class DuplicateLinksFinder
  DEFAULT_INDICES_TO_SEARCH = %w(detailed government govuk).freeze

  def initialize(elasticsearch_url: nil, indices: DEFAULT_INDICES_TO_SEARCH)
    @client = Elasticsearch::Client.new(host: elasticsearch_url || SearchConfig.new.elasticsearch["base_uri"])
    @indices = indices
  end

  def find_exact_duplicates
    body = {
      query: {
        bool: {
          must: { match_all: {} },
        },
      },
      aggs: {
        dups: {
          filter: Search::FormatMigrator.new.call,
          aggs: {
            duplicates: {
              terms: {
                field: "link",
                order: { _count: "desc" },
                size: 100000,
                min_doc_count: 2
              }
            }
          }
        }
      },
      post_filter: Search::FormatMigrator.new.call,
      size: 0,
    }
    results = client.search(index: indices, body: body)
    results["aggregations"]["dups"]["duplicates"]["buckets"].map { |duplicate| duplicate["key"] }
  end

  # Find items whose link is a full URL which duplicate items whose links are just the path
  # e.g. `https://www.gov.uk/ministers` and `/ministers`
  def find_full_url_duplicates(query)
    results = client.search(index: indices, body: query)

    results['hits']['hits'].select do |item|
      link = item['_source']['link']
      if link.start_with?('https://www.gov.uk')
        result = find_path_duplicate(link)

        if result['hits']['hits'].empty?
          puts "Skipping #{link} as it has no duplicates"
          false
        else
          puts "Including #{link} for deletion"
          true
        end
      else
        puts "Skipping #{item['link']} as it does not start with https://www.gov.uk"
        false
      end
    end
  end

private

  attr_reader :client, :indices

  def find_path_duplicate(link)
    client.search(
      index: indices,
      body: {
        filter: {
          term: {
            link: link.gsub('https://www.gov.uk', '')
          }
        }
      }
    )
  end
end
