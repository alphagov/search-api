module QueryComponents
  class UserFilter < BaseComponent
    include Search::QueryHelpers

    attr_reader :rejects, :filters

    def initialize(search_params = QueryParameters.new)
      super
      @rejects, @filters = search_params.filters.partition { |filter| filter.operation == :reject }
    end

    def selected_queries(excluding = [])
      remaining = exclude_fields_from_filters(excluding, filters)
      remaining.map { |filter| filter_hash(filter) }
    end

    def rejected_queries(excluding = [])
      remaining = exclude_fields_from_filters(excluding, rejects)
      remaining.map { |filter| filter_hash(filter) }
    end

  private

    def filter_hash(filter)
      es_filters = []

      if filter.include_missing
        es_filters << { bool: { must_not: { exists: { field: filter.field_name } } } }
      end

      field_name = filter.field_name
      values = filter.values

      case filter.type
      when "string"
        if filter.multivalue_query == :any
          es_filters << terms_filter(field_name, values)
        else # :all
          es_filters << bool_must_filter(field_name, values)
        end
      when "date"
        es_filters << date_filter(field_name, values.first)
      when "boolean"
        es_filters << bool_must_filter(field_name, values)
      else
        raise "Filter type not supported"
      end

      combine_by_should(es_filters)
    end

    def exclude_fields_from_filters(excluded_field_names, filters)
      filters.reject do |filter|
        excluded_field_names.include?(filter.field_name)
      end
    end
  end
end
