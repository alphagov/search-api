require 'pry'

module Debug
  class Explainotron
    def self.explain!(query, ab_tests: {})
      client = Services.elasticsearch

      parsed_params = {
        query: query,
        ab_tests: ab_tests,
        debug: { explain: true, disable_best_bets: true, disable_popularity: true, disable_boosting: true }
 }
      search_params = Search::QueryParameters.new(parsed_params)

      query_builder = Search::QueryBuilder.new(
        search_params: search_params,
        content_index_names: SearchConfig.instance.content_index_names,
        metasearch_index: SearchConfig.instance.metasearch_index
      )
      search_query = query_builder.payload
      pp search_query[:query]

      results = client.search(
        index: "govuk,mainstream,detailed,government",
        analyzer: 'with_search_synonyms',
        body: search_query
      )["hits"]["hits"]

      # rubocop:disable Lint/Debugger
      binding.pry
    end
  end
end
