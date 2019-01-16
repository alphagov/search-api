module LegacySearch
  class AdvancedSearchQueryBuilder
    include Search::Escaping

    def initialize(keywords, filter_params, sort_order, mappings)
      @keywords = keywords
      @filter_params = filter_params
      @mappings = mappings
      @sort_order = sort_order
    end

    def unknown_keys
      if @mappings["edition"]["properties"]["attachments"]
        attachment_keys = @mappings["edition"]["properties"]["attachments"]["properties"].keys.map { |k| "attachments.#{k}" }
      else
        attachment_keys = []
      end

      @unknown_keys ||= @filter_params.keys - (@mappings["edition"]["properties"].keys + attachment_keys)
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
      (value.to_s !~ BOOLEAN_TRUTHY) && (value.to_s !~ BOOLEAN_FALSEY)
    end

    def invalid_date_properties
      @invalid_date_properties ||=
        @filter_params
          .select { |property, _| date_properties.include?(property) }
          .select { |_, value| invalid_date_property_value?(value) }
    end

    def invalid_date_property_value?(value)
      # invalid if it's not a hash, or is an empty hash, or has keys other
      # than 'from' or 'to', or the values are not YYYY-MM-DD
      # formatted.
      !(value.is_a?(Hash) &&
        value.keys.any? &&
        (value.keys - %w(from to before after)).empty? &&
        (value.values.reject { |date| date.to_s =~ /\A\d{4}-\d{2}-\d{2}\Z/ }).empty?)
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
      errors << invalid_boolean_properties.map { |p, v| "Invalid value #{v.inspect} for boolean property \"#{p}\"" } if invalid_boolean_properties.any?
      errors << invalid_date_properties.map { |p, v| "Invalid value #{v.inspect} for date property \"#{p}\"" } if invalid_date_properties.any?
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
            function_score: {
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
                        analyzer: "with_search_synonyms"
                      }
                    }
                  ]
                }
              },
              functions: [
                filter: { term: { search_format_types: "edition" } },
                script_score: {
                  script: {
                    lang: "painless",
                    inline: "((0.15 / ((3.1*Math.pow(10,-11)) * Math.abs(params.now - doc['public_timestamp'].date.getMillis()) + 0.05)) + 0.5)",
                    params: {
                      now: time_in_millis_to_nearest_minute
                    },
                  },
                }
              ]
            }
          }
        }
      else
        { "query" => { "match_all" => {} } }
      end
    end

    def time_in_millis_to_nearest_minute
      (Time.now.to_i / 60) * 60000
    end

    def filter_query_hash
      # Withdrawn documents should never be part of advanced search
      withdrawn_query = { "not" => { "term" => { "is_withdrawn" => true } } }

      filters = filters_hash
      filters << withdrawn_query

      if filters.size > 1
        filters = { "and" => filters }
      else
        filters = filters.first
      end
      { "filter" => filters || {} }
    end

    def order_query_hash
      if @sort_order
        { "sort" => [@sort_order] }
      else
        {}
      end
    end

    def filters_hash
      filters = @filter_params.map do |property, filter_value|
        if date_properties.include?(property)
          date_property_filter(property, filter_value)
        elsif boolean_properties.include?(property)
          boolean_property_filter(property, filter_value)
        elsif Array(filter_value).compact.any? # skip when only nil values are present
          standard_property_filter(property, filter_value)
        end
      end

      filters.compact
    end

    def date_property_filter(property, filter_value)
      filter = { "range" => { property => {} } }
      if filter_value.has_key?("from")
        filter["range"][property]["from"] = filter_value["from"]
      end
      if filter_value.has_key?("to")
        filter["range"][property]["to"] = filter_value["to"]
      end
      # Deprecated date range options
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
        { "term" => { property => true } }
      elsif filter_value.to_s =~ BOOLEAN_FALSEY
        { "term" => { property => false } }
      end
    end

    def standard_property_filter(property, filter_value)
      if filter_value.is_a?(Array) && filter_value.size > 1
        { "terms" => { property => filter_value } }
      else
        { "term" => { property => filter_value.is_a?(Array) ? filter_value.first : filter_value } }
      end
    end

    def date_properties
      @date_properties ||= @mappings["edition"]["properties"].select { |_p, h| h["type"] == "date" }.keys
    end

    def boolean_properties
      @boolean_properties ||= @mappings["edition"]["properties"].select { |_p, h| h["type"] == "boolean" }.keys
    end
  end
end
