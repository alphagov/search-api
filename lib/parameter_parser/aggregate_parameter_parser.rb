class AggregateParameterParser < BaseParameterParser
  attr_reader :parsed_params, :errors, :allowed_return_fields

  def initialize(field, value, allowed_return_fields)
    super()
    @field = field
    @allowed_return_fields = allowed_return_fields
    process(value)
  end

private

  # Return a string to be used in error messages
  def aggregate_description
    %( in aggregate "#{@field}")
  end

  def process(value)
    # Prevent exceptions later on by turning a nil value into an empty string
    value = "" if value.nil?

    options = value.split(",")

    @errors = []

    # @used_params is populated as a side effect of the methods used to build
    # up the hash of parsed params.
    @used_params = []

    # First parameter is just an integer; subsequent ones are key:value
    requested = parse_positive_integer(options.shift, %(first parameter for aggregate "#{@field}"))
    @params = parse_options_into_hash(options)

    @parsed_params = {
      requested:,
      scope:,
      order:,
      examples:,
      example_fields:,
      example_scope:,
    }

    if @parsed_params[:examples].positive? && !ALLOWED_EXAMPLE_SCOPES.include?(@parsed_params[:example_scope])
      # global scope means that examples are looked up for each aggregate value
      # across the whole collection, not just for documents matching the query.
      # This is likely to be a surprising default, so we require that callers
      # explicitly ask for it.
      @errors << %(example_scope parameter must be set to 'query' or 'global' when requesting examples)
      @parsed_params[:examples] = 0
    end

    unused_params = @params.keys - @used_params
    unless unused_params.empty?
      @errors << %(Unexpected options#{aggregate_description}: #{unused_params.join(', ')})
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
        @errors << %(Invalid parameter "#{value}"#{aggregate_description}; must be of form "key:value")
      end
    end
    params
  end

  def scope
    value = single_param("scope", aggregate_description)
    if value.nil?
      :exclude_field_filter
    elsif value == "all_filters"
      :all_filters
    elsif value == "exclude_field_filter"
      :exclude_field_filter
    else
      @errors << %("#{value}" is not a valid scope option#{aggregate_description})
      nil
    end
  end

  def order
    orders = character_separated_param("order", ":").map do |order|
      if order.start_with?("-")
        [order[1..], -1]
      else
        [order, 1]
      end
    end

    valid_orders, invalid_orders = orders.partition do |option, _|
      ALLOWED_AGGREGATE_SORT_OPTIONS.include?(option)
    end

    invalid_orders.each do |option, _|
      @errors << %("#{option}" is not a valid sort option#{aggregate_description})
    end

    result = valid_orders.map do |option, direction|
      [option.to_sym, direction]
    end

    if result.empty?
      DEFAULT_AGGREGATE_SORT
    else
      result
    end
  end

  def examples
    value = single_integer_param("examples", 0, aggregate_description)
    if value != 0 && !(ALLOWED_AGGREGATE_EXAMPLE_FIELDS.include? @field)
      @errors << %(Aggregate examples are not supported#{aggregate_description})
      value = 0
    end
    value
  end

  def example_fields
    fields = character_separated_param("example_fields", ":")
    if fields.empty?
      return DEFAULT_AGGREGATE_EXAMPLE_FIELDS
    end

    disallowed_fields = fields - allowed_return_fields
    fields -= disallowed_fields

    if disallowed_fields.any?
      @errors << %(Some requested fields are not valid return fields: #{disallowed_fields} in parameter "example_fields" in aggregate "#{@field}")
    end
    fields
  end

  def example_scope
    scope = single_param("example_scope", aggregate_description)
    case scope
    when "global"
      :global
    when "query"
      :query
    end
  end
end
