module Search
  # Builds a query for a search across all GOV.UK indices
  class QueryBuilder
    include Search::QueryHelpers

    attr_reader :search_params

    def initialize(search_params:, metasearch_index:, include_suggestions: false)
      @search_params = search_params
      @metasearch_index = metasearch_index
      @include_suggestions = include_suggestions
    end

    def payload
      hash_without_blank_values(
        from: search_params.start,
        size: search_params.count,
        _source: {
          includes: fields.uniq,
        },
        query:,
        post_filter: filter,
        sort:,
        aggs: aggregates,
        highlight:,
        explain: search_params.debug[:explain],
        suggest:,
      )
    end

    # `title`, `description` always needed to potentially populate virtual
    # fields. If not explicitly requested they will not be sent to the user.
    # The same applies to all `*_content_ids` in order to be able to expand
    # their corresponding fields without having to request both fields
    # explicitly.
    # popularity is required as a feature for LearnToRank.
    def fields
      search_params.return_fields +
        %w[document_type
           title
           description
           organisation_content_ids
           mainstream_browse_page_content_ids
           popularity
           format
           link
           public_timestamp
           updated_at
           indexable_content]
    end

    def query
      return { match_all: {} } if search_params.query.nil?

      core_query = QueryComponents::CoreQuery.new(search_params)

      best_bets.wrap(
        popularity_boost.wrap(
          format_boost.wrap(
            core_query.mixed_quoted_unquoted_query,
          ),
        ),
      )
    end

    def filter
      QueryComponents::Filter.new(search_params).payload
    end

  private

    attr_reader :metasearch_index, :include_suggestions

    def suggest
      return {} unless include_suggestions

      QueryComponents::Suggest.new(search_params).payload
    end

    def best_bets
      QueryComponents::BestBets.new(metasearch_index:, search_params:)
    end

    def popularity_boost
      QueryComponents::Popularity.new(search_params)
    end

    def format_boost
      QueryComponents::Booster.new(search_params)
    end

    def sort
      QueryComponents::Sort.new(search_params).payload
    end

    def aggregates
      QueryComponents::Aggregates.new(search_params).payload
    end

    def highlight
      QueryComponents::Highlight.new(search_params).payload
    end

    def hash_without_blank_values(hash)
      Hash[hash.reject do |_key, value|
        [nil, [], {}].include?(value)
      end]
    end
  end
end
