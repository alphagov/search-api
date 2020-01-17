# Performs a search across all indices used for the GOV.UK site search
module Search
  class Query
    class Error < StandardError; end
    class NumberOutOfRange < Error; end
    class QueryTooLong < Error; end

    attr_reader :index, :registries, :spelling_index, :suggestion_blocklist

    def initialize(registries:, content_index:, metasearch_index:, spelling_index:)
      @index = content_index
      @registries = registries
      @metasearch_index = metasearch_index
      @spelling_index = spelling_index
      @suggestion_blocklist = SuggestionBlocklist.new(registries)
    end

    def query(search_params)
      builder_payload = timed_build_query(search_params)
      builder_payload[:payload]
    end

    # Search and combine the indices and return a hash of ResultSet objects
    def run(search_params)
      log_search
      builder_payload = timed_build_query(search_params)
      builder = builder_payload[:builder]
      payload = builder_payload[:payload]

      es_response = process_elasticsearch_errors { timed_raw_search(payload) }
      reranked_response = rerank(es_response, search_params)
      process_es_response(search_params, builder, payload, reranked_response[:es_response], reranked_response[:reranked])
    end

  private

    attr_reader :metasearch_index

    def timed_build_query(search_params)
      GovukStatsd.time("build_query") do
        builder = QueryBuilder.new(
          search_params: search_params,
          content_index_names: content_index_names,
          metasearch_index: metasearch_index,
        )

        payload = process_elasticsearch_errors { builder.payload }

        { builder: builder, payload: payload }
      end
    end

    def timed_raw_search(payload)
      GovukStatsd.time("elasticsearch.raw_search") do
        index.raw_search(payload)
      end
    end

    def content_index_names
      # index is a IndexForSearch object, which combines all the content indexes
      index.index_names
    end

    def fetch_spell_checks(search_params)
      SpellCheckFetcher.new(search_params, registries).es_response
    end

    def process_elasticsearch_errors
      yield
    rescue Elasticsearch::Transport::Transport::Errors::InternalServerError => e
      case e.message
      when /Numeric value \(([0-9]*)\) out of range of/
        raise(NumberOutOfRange, "Integer value of #{$1} exceeds maximum allowed")
      when /maxClauseCount is set to/
        raise(QueryTooLong, "Query must be less than 1024 words")
      else
        raise
      end
    end

    def rerank(es_response, search_params)
      return { reranked: false, es_response: es_response } unless search_params.rerank

      results = es_response.dig("hits", "hits").to_a
      return { reranked: false, es_response: es_response } if results.empty? || results[0].fetch("_score").nil?

      reranked = LearnToRank::Reranker.new.rerank(
        es_results: results,
        query: search_params.query,
      )

      return { reranked: false, es_response: es_response } if reranked.nil?

      es_response["hits"]["hits"] = reranked
      { reranked: true, es_response: es_response }
    end

    def process_es_response(search_params, builder, payload, es_response, reranked)
      # Augment the response with the suggest result from a separate query.
      if search_params.suggest_spelling?
        es_response["suggest"] = run_spell_checks(search_params)
      end

      if search_params.suggest_autocomplete?
        es_response["autocomplete"] = run_autocomplete_query(search_params)
      end

      presented_aggregates = present_aggregates_with_examples(search_params, es_response, builder)

      ResultSetPresenter.new(
        search_params: search_params,
        es_response: es_response,
        registries: registries,
        presented_aggregates: presented_aggregates,
        schema: index.schema,
        query_payload: payload,
        reranked: reranked,
      ).present
    end

    def present_aggregates_with_examples(search_params, es_response, builder)
      presented_aggregates = AggregateResultPresenter.new(
        es_response["aggregations"],
        search_params,
        registries,
      ).presented_aggregates

      slugs_for_fields = presented_aggregates.each_with_object({}) do |(field, aggregate), acc|
        current = acc[field] || []
        new = aggregate[:options].map { |option| option[:value]["slug"] }.compact
        acc[field] = (current + new).uniq
        acc
      end

      example_fetcher = AggregateExampleFetcher.new(index, es_response, search_params, builder)
      examples = example_fetcher.fetch(slugs_for_fields)
      AggregateResultPresenter.merge_examples(presented_aggregates, examples)

      presented_aggregates
    end

    # Elasticsearch tries to find spelling suggestions for words that don't occur in
    # our content, as they are probably mispelled. However, currently it is
    # returning suggestions for words that do not occur in *every* index. Because
    # some indexes contain very few words, Elasticsearch returns too many spelling
    # suggestions for common terms. For example, using the suggester on all indices
    # will yield a suggestion for "PAYE", because it's mentioned only in the
    # `government` index, and not in other indexes.
    #
    # This issue is mentioned in
    # https://github.com/elastic/elasticsearch/issues/7472.
    #
    # Our solution is to run a separate query to fetch the suggestions, only using
    # the indices we want.
    def run_spell_checks(search_params)
      return unless suggestion_blocklist.should_correct?(search_params.query)

      query = {
        size: 0,
        suggest: QueryComponents::Suggest.new(search_params).payload,
      }

      response = spelling_index.raw_search(query)

      response["suggest"]
    end

    def run_autocomplete_query(search_params)
      query = {
        _source: "title",
        query: QueryComponents::Autocomplete.new(search_params).payload,
      }

      response = index.raw_search(query)

      response["hits"]
    end

    def log_search
      GovukStatsd.increment "search_query"
    end
  end
end
