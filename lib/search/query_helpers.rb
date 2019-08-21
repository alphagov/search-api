module Search
  # Mixin for building elasticsearch queries
  module QueryHelpers
  private

    def combine_by_should(filters)
      filters = filters.compact
      if filters.empty?
        nil
      elsif filters.length == 1
        filters.first
      else
        { bool: { should: filters } }
      end
    end

    def bool_must_filter(field_name, values)
      {
        bool: {
          must: values.map { |value| { term: { field_name => value } } }
        }
      }
    end

    def terms_filter(field_name, values)
      return nil if values.empty?

      { "terms" => { field_name => values } }
    end

    def term_filter(field_name, value)
      { "term" => { field_name => value } }
    end

    def date_filter(field_name, value)
      {
        "range" => {
          field_name => {
            "from" => value["from"].iso8601,
            "to" => value["to"].iso8601,
          }.reject { |_, v| v.nil? }
        }
      }
    end

    def dis_max_query(queries, tie_breaker: 0.0, boost: 1.0)
      # Calculates a score by running all the queries, and taking the maximum.
      # Adds in the scores for the other queries multiplied by `tie_breaker`.
      if queries.size == 1
        queries.first
      else
        {
          dis_max: {
            queries: queries,
            tie_breaker: tie_breaker,
            boost: boost,
          }
        }
      end
    end

    def should_coord_query(queries)
      # Calculates a score by running all the queries and then
      # multiplying by the fraction which match:
      #
      # score = sum(query_scores) * num(matching_queries) / num(queries)
      if queries.size == 1
        queries.first
      else
        {
          function_score: {
            query: { bool: { should: queries } },
            score_mode: "sum",
            boost_mode: "multiply",
            functions: queries.map do |q|
              {
                filter: q,
                weight: 1.0 / queries.size
              }
            end
          }
        }
      end
    end
  end
end
