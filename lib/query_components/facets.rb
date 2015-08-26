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
      if options[:scope] == :exclude_field_filter
        facet_filter = filters_hash([field_name])
      elsif options[:scope] == :all_filters
        facet_filter = filters_hash([])
      end

      unless facet_filter.nil?
        facet_hash[:facet_filter] = facet_filter
      end

      facet_hash
    end

    # Possible duplication.
    def filters_hash(excluding)
      QueryComponents::Filter.new(search_params).payload(excluding)
    end
  end
end
