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
      remaining.map { |filter| filter_hash(filter) }.flatten
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

      # eg. values = `{"and"=>{"0"=>["a", "b"], "1"=>["c", "d"]}}`
      if values.is_a?(Hash) && values.keys == %W(and)
        es_filters + nested_filters(field_name, values)
      else
        es_filters << send("#{filter.type}_filter_hash", filter, field_name, values)
        combine_by_should(es_filters)
      end
    end

    def date_filter_hash(_, field_name, values)
      date_filter(field_name, values.first)
    end

    def string_filter_hash(filter, field_name, values)
      if filter.multivalue_query == :any
        terms_filter(field_name, values)
      else # :all
        bool_must_filter(field_name, values)
      end
    end

    def nested_filters(field_name, values)
      [].tap do |ary|
        values.fetch("and", []).each do |_, nested_values|
          ary << terms_filter(field_name, nested_values)
        end
      end
    end

    def exclude_fields_from_filters(excluded_field_names, filters)
      filters.reject do |filter|
        excluded_field_names.include?(filter.field_name)
      end
    end
  end
end
