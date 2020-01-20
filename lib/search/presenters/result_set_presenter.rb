module Search
  # Presents a combined set of results for a GOV.UK site search
  class ResultSetPresenter
    attr_reader :es_response, :presented_aggregates, :reranked, :search_params

    # `registries` should be a map from registry names to registries,
    # which gets passed to the ResultSetPresenter class. For example:
    #
    #     { organisations: OrganisationRegistry.new(...) }
    def initialize(search_params:,
                   es_response:,
                   registries: {},
                   presented_aggregates: {},
                   schema: nil,
                   query_payload: {},
                   reranked: false)

      @es_response = es_response
      @aggregates = es_response["aggregations"]
      @search_params = search_params
      @registries = registries
      @presented_aggregates = presented_aggregates
      @schema = schema
      @query_payload = query_payload
      @reranked = reranked
    end

    def present
      response = {
        results: presented_results,
        total: es_response.dig("hits", "total") || 0,
        start: search_params.start,
        search_params.aggregate_name => presented_aggregates,
        suggested_queries: suggested_queries,
        suggested_autocomplete: suggested_autocomplete,
        es_cluster: search_params.cluster.key,
        reranked: reranked,
      }

      if search_params.show_query?
        response["elasticsearch_query"] = @query_payload
      end

      response
    end

  private

    def suggested_queries
      SpellCheckPresenter.new(es_response).present
    end

    def suggested_autocomplete
      AutocompletePresenter.new(es_response).present
    end

    def presented_results
      es_response.dig("hits", "hits").to_a.map do |raw_result|
        ResultPresenter.new(raw_result.to_hash, @registries, @schema, search_params).present
      end
    end
  end
end
