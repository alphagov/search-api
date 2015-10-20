module QueryComponents
  class Filter < BaseComponent
    def payload(param_filters = nil)
      param_filters ||= search_params.filters

      rejects = []
      filters = []

      param_filters.each do |filter|
        if filter.reject
          rejects << filter_hash(filter)
        else
          filters << filter_hash(filter)
        end
      end

      filters = combine_filters(filters, :and)
      rejects = combine_filters(rejects, :and)

      if filters
        if rejects
          {
            bool: {
              must: filters,
              must_not: rejects,
            }
          }
        else
          filters
        end
      else
        if rejects
          {
            not: rejects
          }
        else
          nil
        end
      end
    end

    private

    # Combine filters using an operator
    #
    # `filters` should be a sequence of filters. nil filters are ignored.
    # `op` should be :and or :or
    #
    # If 0 non-nil filters are supplied, returns nil.  Otherwise returns the
    # elasticsearch query required to match the filters
    def combine_filters(filters, op)
      filters = filters.compact
      if filters.length == 0
        nil
      elsif filters.length == 1
        filters.first
      else
        {op => filters}
      end
    end

    def filter_hash(filter)
      es_filters = []

      if filter.include_missing
        es_filters << {"missing" => { field: filter.field_name } }
      end

      case filter.type
      when "string"
        es_filters << terms_filter(filter)
      when "date"
        es_filters << date_filter(filter)
      else
        raise "Filter type not supported"
      end

      combine_filters(es_filters, :or)
    end

    def terms_filter(filter)
      if filter.values.size > 0
        {"terms" => { filter.field_name => filter.values } }
      end
    end

    def date_filter(filter)
      value = filter.values.first

      {
        "range" => {
          filter.field_name => {
            "from" => value["from"].iso8601,
            "to" => value["to"].iso8601,
          }.reject { |_, v| v.nil? }
        }
      }
    end
  end
end
