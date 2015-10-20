module QueryComponents
  class Facets < BaseComponent
    def payload
      search_params.facets.reduce({}) do |result, (field_name, options)|
        result[field_name] = facet_hash_for_facet(field_name, options)
        result
      end
    end

    private

    def facet_hash_for_facet(field_name, options)
      facet_hash = {
        terms: {
          field: field_name,
          order: "count",
        }
      }

      # The scope of the facet.
      #
      # Defaults to "exclude_field_filter", meaning that facet values should be
      # calculated as if no filters are applied to the field the facet is for.
      # This is appropriate for populating multi-select facet filter boxes, to
      # allow other facet values to be chosen.
      #
      # May also be 'all_filters", to mean that facet values should be calculated
      # after applying all filters - ie, just on the documents which will be
      # included in the result set.
      filters = if options[:scope] == :exclude_field_filter
        search_params.filters.reject do |filter|
          filter.field_name == field_name
        end
      elsif options[:scope] == :all_filters
        search_params.filters
      else
        []
      end

      if filters.any?
        facet_hash[:facet_filter] = filter_query_for_filters(filters)
      end

      facet_hash
    end

    def filter_query_for_filters(filters)
      QueryComponents::Filter.new(search_params).payload(filters)
    end
  end
end
