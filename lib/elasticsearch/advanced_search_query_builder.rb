require "elasticsearch/escaping"

module Elasticsearch
  class AdvancedSearchQueryBuilder
    include Elasticsearch::Escaping

    def initialize(keywords, filter_params, sort_order, mappings)
      @keywords = keywords
      @filter_params = filter_params
      @mappings = mappings
      @sort_order = sort_order
    end

    def unknown_keys
      @unknown_keys ||= @filter_params.keys - @mappings["edition"]["properties"].keys
    end

    def unknown_sort_key
      if @sort_order
        @unknown_sort_key ||= @sort_order.keys - @mappings['edition']['properties'].keys
      else
        []
      end
    end

    def invalid_boolean_properties
      @invalid_boolean_properties ||=
        @filter_params
          .select { |property, _| boolean_properties.include?(property) }
          .select { |_, value| invalid_boolean_property_value?(value) }
    end

    BOOLEAN_TRUTHY = /\A(true|1)\Z/i
    BOOLEAN_FALSEY = /\A(false|0)\Z/i
    def invalid_boolean_property_value?(value)
      (value.to_s !~ BOOLEAN_TRUTHY ) && (value.to_s !~ BOOLEAN_FALSEY)
    end

    def invalid_date_properties
      @invalid_date_properties ||=
        @filter_params
          .select { |property, _| date_properties.include?(property) }
          .select { |_, value| invalid_date_property_value?(value) }
    end

    def invalid_date_property_value?(value)
      # invalid if it's not a hash, or is an empty hash, or has keys other
      # than 'before' or 'after', or the values are not YYYY-MM-DD
      # formatted.
      !(value.is_a?(Hash) &&
        value.keys.any? &&
        (value.keys - ['before', 'after']).empty? &&
        (value.values.reject { |date| date.to_s =~ /\A\d{4}-\d{2}-\d{2}\Z/}).empty?)
    end

    def valid?
      unknown_keys.empty? &&
        unknown_sort_key.empty? &&
        invalid_boolean_properties.empty? &&
        invalid_date_properties.empty?
    end

    def error
      errors = []
      errors << "Querying unknown properties #{unknown_keys.inspect}" if unknown_keys.any?
      errors << "Sorting on unknown property #{unknown_sort_key.inspect}" if unknown_sort_key.any?
      errors << invalid_boolean_properties.map { |p, v| "Invalid value #{v.inspect} for boolean property \"#{p}\""} if invalid_boolean_properties.any?
      errors << invalid_date_properties.map { |p, v| "Invalid value #{v.inspect} for date property \"#{p}\""} if invalid_date_properties.any?
      errors.flatten.join('. ')
    end

    def query_hash
      keyword_query_hash
        .merge(filter_query_hash)
        .merge(order_query_hash)
    end

    def keyword_query_hash
      if @keywords
        {
          query: {
            custom_filters_score: {
              query: {
                bool: {
                  should: [
                    {
                      query_string: {
                        query: escape(@keywords),
                        fields: ["title^3"],
                        default_operator: "and",
                        analyzer: "default"
                      }
                    },
                    {
                      query_string: {
                        query: escape(@keywords),
                        analyzer: "query_default"
                      }
                    }
                  ]
                }
              },
              filters: [
                filter: { term: { search_format_types: "edition" } },
                script: "((0.15 / ((3.1*pow(10,-11)) * abs(time() - doc['public_timestamp'].date.getMillis()) + 0.05)) + 0.5)"
              ]
            }
          }
        }
      else
        {"query" => {"match_all" => {}}}
      end
    end

    def filter_query_hash
      filters = filters_hash
      if filters.size > 1
        filters = {"and" => filters}
      else
        filters = filters.first
      end
      {"filter" => filters || {}}
    end

    def order_query_hash
      if @sort_order
        {"sort" => [@sort_order]}
      else
        {}
      end
    end

    def filters_hash
      @filter_params.map do |property, filter_value|
        if date_properties.include?(property)
          date_property_filter(property, filter_value)
        elsif boolean_properties.include?(property)
          boolean_property_filter(property, filter_value)
        else
          standard_property_filter(property, filter_value)
        end
      end.compact
    end

    def date_property_filter(property, filter_value)
      filter = {"range" => {property => {}}}
      if filter_value.has_key?("after")
        filter["range"][property]["from"] = filter_value["after"]
      end
      if filter_value.has_key?("before")
        filter["range"][property]["to"] = filter_value["before"]
      end
      filter
    end

    def boolean_property_filter(property, filter_value)
      if filter_value.to_s =~ BOOLEAN_TRUTHY
        {"term" => { property => true }}
      elsif filter_value.to_s =~ BOOLEAN_FALSEY
        {"term" => { property => false }}
      end
    end

    def standard_property_filter(property, filter_value)
      if filter_value.is_a?(Array) && filter_value.size > 1
        {"terms" => { property => filter_value } }
      else
        {"term" => { property => filter_value.is_a?(Array) ? filter_value.first : filter_value } }
      end
    end

    def date_properties
      @date_properties ||= @mappings["edition"]["properties"].select { |p,h| h["type"] == "date" }.keys
    end

    def boolean_properties
      @boolean_properties ||= @mappings["edition"]["properties"].select { |p,h| h["type"] == "boolean" }.keys
    end

  end
end
