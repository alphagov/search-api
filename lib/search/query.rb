# Performs a search across all indices used for the GOV.UK site search
module Search
  class Query
    class Error < StandardError; end

    class NumberOutOfRange < Error; end

    class QueryTooLong < Error; end

    attr_reader :index, :registries, :suggestion_blocklist

    def initialize(registries:, content_index:, metasearch_index:)
      @index = content_index
      @registries = registries
      @metasearch_index = metasearch_index
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

      process_es_response(search_params, builder, payload, es_response)
    end

  private

    attr_reader :metasearch_index

    def timed_build_query(search_params)
      include_suggestions = search_params.suggest_spelling? && suggestion_blocklist.should_correct?(search_params.query)

      GovukStatsd.time("build_query") do
        builder = QueryBuilder.new(
          search_params:,
          metasearch_index:,
          include_suggestions:,
        )

        payload = process_elasticsearch_errors { builder.payload }

        { builder:, payload: }
      end
    end

    def timed_raw_search(payload)
      GovukStatsd.time("elasticsearch.raw_search") do
        index.raw_search(payload)
      end
    end

    def process_elasticsearch_errors
      yield
    rescue Elasticsearch::Transport::Transport::Errors::InternalServerError => e
      case e.message
      when /Numeric value \(([0-9]*)\) out of range of/
        raise(NumberOutOfRange, "Integer value of #{Regexp.last_match(1)} exceeds maximum allowed")
      when /maxClauseCount is set to/
        raise(QueryTooLong, "Query must be less than 1024 words")
      else
        raise
      end
    end

    def process_es_response(search_params, builder, payload, es_response)
      # Augment the response with the suggest result from a separate query.
      if search_params.suggest_autocomplete?
        es_response["autocomplete"] = run_autocomplete_query(search_params)
      end

      presented_aggregates = present_aggregates_with_examples(search_params, es_response, builder)

      ResultSetPresenter.new(
        search_params:,
        es_response:,
        registries:,
        presented_aggregates:,
        schema: index.schema,
        query_payload: payload,
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

    def run_autocomplete_query(search_params)
      GovukStatsd.increment "suggest.completion"
      GovukStatsd.time("suggest.completion") do
        query = {
          _source: "autocomplete", # Removes unneeded response from query
          suggest: QueryComponents::Autocomplete.new(search_params).payload,
        }

        response = index.raw_search(query)

        response["suggest"]
      end
    end

    def log_search
      GovukStatsd.increment "search_query"
    end
  end
end
