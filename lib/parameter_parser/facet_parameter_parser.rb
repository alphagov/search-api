require_relative "base_parameter_parser"

class FacetParameterParser < BaseParameterParser
  attr_reader :parsed_params, :errors, :allowed_return_fields

  def initialize(field, value, allowed_return_fields)
    @field = field
    @allowed_return_fields = allowed_return_fields
    process(value)
  end

private
  # Return a string to be used in error messages
  def facet_description
    %{ in facet "#{@field}"}
  end

  def process(value)
    options = value.split(",")

    @errors = []

    # @used_params is populated as a side effect of the methods used to build
    # up the hash of parsed params.
    @used_params = []

    # First parameter is just an integer; subsequent ones are key:value
    requested = parse_positive_integer(options.shift, %{first parameter for facet "#{@field}"})
    @params = parse_options_into_hash(options)

    @parsed_params = {
      requested: requested,
      scope: scope,
      order: order,
      examples: examples,
      example_fields: example_fields,
      example_scope: example_scope,
    }

    if @parsed_params[:examples] > 0 && !ALLOWED_EXAMPLE_SCOPES.include?(@parsed_params[:example_scope])
      # global scope means that examples are looked up for each facet value
      # across the whole collection, not just for documents matching the query.
      # This is likely to be a surprising default, so we require that callers
      # explicitly ask for it.
      @errors << %{example_scope parameter must be set to 'query' or 'global' when requesting examples}
      @parsed_params[:examples] = 0
    end

    unused_params = @params.keys - @used_params
    unless unused_params.empty?
      @errors << %{Unexpected options#{facet_description}: #{unused_params.join(', ')}}
    end
  end

  def parse_options_into_hash(values)
    params = {}
    values.each do |value|
      k_v = value.split(":", 2)
      if k_v.length == 2
        params[k_v[0]] ||= []
        params[k_v[0]] << k_v[1]
      else
        @errors << %{Invalid parameter "#{value}"#{facet_description}; must be of form "key:value"}
      end
    end
    params
  end

  def scope
    value = single_param("scope", facet_description)
    if value.nil?
      :exclude_field_filter
    elsif value == "all_filters"
      :all_filters
    elsif value == "exclude_field_filter"
      :exclude_field_filter
    else
      @errors << %{"#{value}" is not a valid scope option#{facet_description}}
      nil
    end
  end

  def order
    orders = character_separated_param("order", ":").map { |order|
      if order.start_with?('-')
        [order[1..-1], -1]
      else
        [order, 1]
      end
    }

    valid_orders, invalid_orders = orders.partition { |option, _|
      ALLOWED_FACET_SORT_OPTIONS.include?(option)
    }

    invalid_orders.each do |option, _|
      @errors << %{"#{option}" is not a valid sort option#{facet_description}}
    end

    result = valid_orders.map { |option, direction|
      [option.to_sym, direction]
    }

    if result.empty?
      DEFAULT_FACET_SORT
    else
      result
    end
  end

  def examples
    value = single_integer_param("examples", 0, facet_description)
    if value != 0
      unless ALLOWED_FACET_EXAMPLE_FIELDS.include? @field
        @errors << %{Facet examples are not supported#{facet_description}}
        value = 0
      end
    end
    value
  end

  def example_fields
    fields = character_separated_param("example_fields", ":")
    if fields.empty?
      return DEFAULT_FACET_EXAMPLE_FIELDS
    end
    disallowed_fields = fields - allowed_return_fields
    fields = fields - disallowed_fields

    if disallowed_fields.any?
      @errors << %{Some requested fields are not valid return fields: #{disallowed_fields} in parameter "example_fields" in facet "#{@field}"}
    end
    fields
  end

  def example_scope
    scope = single_param("example_scope", facet_description)
    if scope == "global"
      :global
    elsif scope == "query"
      :query
    else
      nil
    end
  end
end
