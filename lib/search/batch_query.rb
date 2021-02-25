module Search
  class BatchQuery < Query
    class TooManyQueries < Error; end

    def run(searches_params)
      raise(TooManyQueries, "Maximum of 10 searches per batch") unless searches_params.count <= 10

      log_search_count(searches_params)
      builders = create_query_builders(searches_params)
      payloads = aggregate_payloads(builders)
      es_responses = timed_msearch(payloads)["responses"]

      searches_params.map.with_index do |search_params, i|
        process_es_response(search_params, builders[i], payloads[i], es_responses[i], false)
      end
    end

  private

    def timed_msearch(payloads)
      GovukStatsd.time("elasticsearch.msearch") do
        index.msearch(payloads)
      end
    end

    def create_query_builders(searches_params)
      searches_params.map do |search_params|
        QueryBuilder.new(
          search_params: search_params,
          content_index_names: SearchConfig.content_index_names,
          metasearch_index: metasearch_index,
        )
      end
    end

    def aggregate_payloads(builders)
      builders.map { |builder| process_elasticsearch_errors { builder.payload } }
    end

    def log_search_count(searches)
      GovukStatsd.increment "batch_search_#{searches.count}_searches"
    end
  end
end
