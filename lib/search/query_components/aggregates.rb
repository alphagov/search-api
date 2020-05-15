module QueryComponents
  class Aggregates < BaseComponent
    def payload
      search_params.aggregates.each_with_object({}) do |(field_name, options), result|
        result[field_name] = aggregates_hash_for_aggregate(field_name, options)
        result["#{field_name}_with_missing_value"] = aggregates_hash_for_null_values(field_name, options)
      end
    end

  private

    def aggregates_hash_for_aggregate(field_name, options)
      with_filters(
        {
          terms: {
            field: field_name,
            order: { _count: "desc" },
            # We want all the aggregate values so we can return an accurate count of
            # the number of options.
            size: 100_000,
          },
        },
        field_name,
        options,
      )
    end

    def aggregates_hash_for_null_values(field_name, options)
      with_filters(
        { missing: { field: field_name } },
        field_name,
        options,
      )
    end

    def with_filters(query, field_name, options)
      # The scope of the aggregate.
      #
      # Defaults to "exclude_field_filter", meaning that aggregate values should be
      # calculated as if no filters are applied to the field the aggregate is for.
      # This is appropriate for populating multi-select aggregate filter boxes, to
      # allow other aggregate values to be chosen.
      #
      # May also be 'all_filters", to mean that aggregate values should be calculated
      # after applying all filters - ie, just on the documents which will be
      # included in the result set.
      if options[:scope] == :exclude_field_filter
        applied_query_filters = filters_hash([field_name])
      elsif options[:scope] == :all_filters
        applied_query_filters = filters_hash([])
      end

      {
        filter: Search::FormatMigrator.new(
          search_params.search_config,
          base_query: applied_filter(applied_query_filters),
        ).call,
        aggs: { "filtered_aggregations" => query },
      }
    end

    def applied_filter(applied_query_filters)
      if applied_query_filters && applied_query_filters.count.positive?
        applied_query_filters
      else
        { match_all: {} }
      end
    end

    def filters_hash(excluding)
      QueryComponents::Filter.new(search_params).payload(excluding)
    end
  end
end
