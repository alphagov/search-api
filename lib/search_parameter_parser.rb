require "ostruct"
require "unf"

class BaseParameterParser

  # The fields listed here are the only ones which the search results can be
  # ordered by.  These are listed and validated explicitly because
  # sorting by arbitrary fields can be expensive in terms of memory usage in
  # elasticsearch, and because elasticsearch gives fairly obscure error
  # messages if undefined sort fields are used.
  ALLOWED_SORT_FIELDS = %w(
    last_update
    public_timestamp
    closing_date
    title
  )

  SORT_MAPPINGS = {
    "title" => "title.sort"
  }

  # Incoming filter fields will have their names transformed according to the
  # following mapping. Fields not listed here will be passed through unchanged.
  FILTER_NAME_MAPPING = {
    "document_type" => "_type",
  }

  # The fields listed here are the only ones which can be used to calculated
  # facets for.  This should be a subset of allowed_filter_fields
  ALLOWED_FACET_FIELDS = %w(
    detailed_format
    document_collections
    format
    mainstream_browse_pages
    manual
    organisations
    people
    policies
    search_format_types
    section
    specialist_sectors
  )

  # The fields for which facet examples are allowed to be requested.
  # This is locked down because these can only be requested with the current
  # version of elasticsearch by performing a separate query for each facet
  # option.  This is done using the msearch API to perform many queries
  # together, but is still potentially expensive.  They could be efficiently
  # calculated with the top-documents aggregator in elasticsearch 1.3, so this
  # restriction could be relaxed in future.
  ALLOWED_FACET_EXAMPLE_FIELDS = %w(
    format
    mainstream_browse_pages
    manual
    organisations
    section
    specialist_sectors
  )

  # The keys by which facet values can be sorted (using the "order" option).
  # Multiple can be supplied, separated by colons - items which are equal
  # according to the first option are sorted by the next key, etc.  keys can be
  # preceded with a "-" to sort in descending order.
  #  - filtered: sort fields which have filters applied to them first.
  #  - count: sort values by number of matching documents.
  #  - value: sort by value if string, sort by title if not a string
  #  - value.slug: sort values by the slug part of the value.
  #  - value.title: sort values by the title of the value.
  #  - value.link: sort values by the link of the value.
  # 
  ALLOWED_FACET_SORT_OPTIONS = %w(
    filtered
    count
    value
    value.slug
    value.title
    value.link
  )

  # Scopes that are allowed when requesting examples for facets
  #  - query: Return only examples that match the query and filters
  #  - global: Return examples for the facet regardless of whether they match
  #            the query and filters
  ALLOWED_EXAMPLE_SCOPES = [:global, :query]

  # The fields which are returned by default for search results.
  DEFAULT_RETURN_FIELDS = %w(
    description
    display_type
    document_series
    format
    link
    organisations
    public_timestamp
    section
    slug
    specialist_sectors
    subsection
    subsubsection
    title
    topics
    world_locations
  )

  # Default order in which facet results are sorted
  DEFAULT_FACET_SORT = [
    [:filtered, 1],
    [:count, -1],
    [:slug, 1],
  ]

  # The fields which are returned by default for facet examples.
  DEFAULT_FACET_EXAMPLE_FIELDS = %w(
    link
    title
  )

  # A special value used to filter for missing fields.
  MISSING_FIELD_SPECIAL_VALUE = "_MISSING"

  attr_reader :parsed_params, :errors

  def valid?
    @errors.empty?
  end

protected

  def parse_positive_integer(value, description)
    begin
      result = Integer(value, 10)
    rescue ArgumentError
      @errors << %{Invalid value "#{value}" for #{description} (expected positive integer)}
      return nil
    end
    if result < 0
      @errors << %{Invalid negative value "#{value}" for #{description} (expected positive integer)}
      return nil
    end
    result
  end

  # Get a parameter that occurs at most once
  # Returns the string value of the parameter, or nil
  def single_param(param_name, description="")
    @used_params << param_name
    values = @params.fetch(param_name, [])
    if values.size > 1
      @errors << %{Too many values (#{values.size}) for parameter "#{param_name}"#{description} (must occur at most once)}
    end
    values.first
  end

  # Get a parameter represented as a comma separated list
  # Multiple occurrences of the parameter will be joined together
  def character_separated_param(param_name, separator=",")
    @used_params << param_name
    values = @params.fetch(param_name, [])
    values.map { |value|
      value.split(separator)
    }.flatten
  end

  # Parse a parameter which should contain an integer and occur only once
  # Returns the integer value, or nil
  def single_integer_param(param_name, default, description="")
    value = single_param(param_name, description)
    unless value.nil?
      value = parse_positive_integer(value, %{parameter "#{param_name}"#{description}})
    end
    if value.nil?
      return default
    end
    value
  end
end

class SearchParameterParser < BaseParameterParser
  def initialize(params, schema)
    @schema = schema
    process(params)
  end

  def error
    @errors.join(". ")
  end

private

  def process(params)
    @params = params
    @errors = []

    # @used_params is populated as a side effect of the methods used to build
    # up the hash of parsed params.
    @used_params = []

    @parsed_params = {
      start: single_integer_param("start", 0),
      count: single_integer_param("count", 10),
      query: normalize_query(single_param("q")),
      order: order,
      return_fields: return_fields,
      filters: filters,
      facets: facets,
      debug: debug_options,
    }

    unused_params = @params.keys - @used_params
    unless unused_params.empty?
      @errors << "Unexpected parameters: #{unused_params.join(', ')}"
    end
  end

  def normalize_query(query)
    unless query.nil?
      query = normalize_unicode(query, "query")
    end
    unless query.nil?
      query = query.strip
      if query.length == 0
        nil
      else
        query
      end
    end
  end

  def normalize_unicode(s, description)
    normalizer = UNF::Normalizer.instance
    begin
      # Put strings into NFKC-normal form to ensure that accent handling works
      # correctly in elasticsearch.
      normalizer.normalize(s, :nfkc).strip
    rescue ArgumentError
      @errors << %{Invalid unicode in #{description}}
      return nil
    end
  end

  # Get the order for search results to be returned in.
  def order
    order = single_param("order")
    if order.nil?
      return nil
    end
    if order.start_with?('-')
      field = order[1..-1]
      dir = "desc"
    else
      field = order
      dir = "asc"
    end
    unless ALLOWED_SORT_FIELDS.include?(field)
      @errors << %{"#{field}" is not a valid sort field}
      return nil
    end
    return [SORT_MAPPINGS.fetch(field, field), dir]
  end

  # Get a list of the fields to request in results from elasticsearch
  def return_fields
    fields = character_separated_param("fields")
    if fields.empty?
      return DEFAULT_RETURN_FIELDS
    end
    disallowed_fields = fields - allowed_return_fields
    fields = fields - disallowed_fields

    if disallowed_fields.any?
      @errors << "Some requested fields are not valid return fields: #{disallowed_fields}"
    end
    fields
  end

  def parameters_starting_with(prefix)
    @params.select { |name, _|
      name.start_with?(prefix)
    }.each_with_object({}) { |(name, value), result|
      @used_params << name
      result[name.sub(prefix, "")] = value
    }
  end

  def validate_filter_parameters(parameters, type)
    allowed, disallowed = parameters.partition { |field, _|
      allowed_filter_fields.include?(field)
    }

    disallowed.each do |field, _|
      @errors << %{"#{field}" is not a valid #{type} field}
    end

    allowed
  end

  def filters
    filter_parameters = parameters_starting_with("filter_")
    reject_parameters = parameters_starting_with("reject_")

    build_filters(
      validate_filter_parameters(filter_parameters, "filter"),
      validate_filter_parameters(reject_parameters, "reject")
    )
  end

  def build_filters(filter_parameters, reject_parameters)
    filters = filter_parameters.map { |field, values|
      build_filter(filter_name_lookup(field), values, false)
    }.compact

    rejects = reject_parameters.map { |field, values|
      build_filter(filter_name_lookup(field), values, true)
    }.compact

    filters.concat(rejects)
  end

  def allowed_filter_fields
    # document_type is a special case, because it's an alias for the internal
    # "_type" field.
    ["document_type"] + @schema.allowed_filter_fields
  end

  def allowed_return_fields
    @schema.field_definitions.keys
  end

  def schema_get_field_type(field_name)
    @schema.field_definitions.fetch(field_name).type
  end

  def build_filter(field_name, values, reject)
    if field_name == '_type'
      filter_type = "text"
    else
      filter_type = @schema.field_definitions.fetch(field_name).type.filter_type
    end

    if filter_type.nil?
      @errors << %{"#{field_name}" has no filter_type defined}
      return nil
    end

    filter_class = {
      "text" => TextFieldFilter,
      "date" => DateFieldFilter,
    }.fetch(filter_type)

    filter = filter_class.new(field_name, values, reject)
    if filter.valid?
      filter
    else
      @errors.concat(filter.errors)
      nil
    end
  end

  class Filter
    attr_reader :field_name, :include_missing, :values, :reject, :errors

    def initialize(field_name, values, reject)
      @field_name = field_name
      @include_missing = values.include? BaseParameterParser::MISSING_FIELD_SPECIAL_VALUE
      @values = Array(values).reject { |value| value == BaseParameterParser::MISSING_FIELD_SPECIAL_VALUE }
      @reject = reject
      @errors = []
    end

    def type
      raise NotImplementedError
    end

    def ==(other)
      [field_name, values, reject] == [other.field_name, other.values, other.reject]
    end

    def valid?
      errors.empty?
    end
  end

  class DateFieldFilter < Filter
    def initialize(field_name, values, reject)
      super
      @values = parse_dates(@values)
    end

    def type
      "date"
    end

  private
    def parse_dates(values)
      if values.count > 1
        @errors << %{Too many values (#{values.size}) for parameter "#{field_name}" (must occur at most once)}
      end

      values.map { |combined_from_and_to|
        dates_hash = combined_from_and_to.split(",").reduce({}) { |dates, param|
          key, date = param.split(":")
          dates.merge(key => parse_date(date))
        }

        Value.new(
          dates_hash.fetch("from", null_date),
          dates_hash.fetch("to", null_date),
        )
      }
    end

    def parse_date(string)
      Date.parse(string)
    rescue
      @errors << %{Invalid value "#{string}" for parameter "#{field_name}" (expected ISO8601 date}
      null_date
    end

    def null_date
      OpenStruct.new(iso8601: nil)
    end

    Value = Struct.new(:from, :to)
  end

  class TextFieldFilter < Filter
    def type
      "string"
    end
  end

  def filter_name_lookup(name)
    FILTER_NAME_MAPPING.fetch(name, name)
  end

  def facets
    facets = {}
    @params.each do |key, values|
      if (m = key.match(/\Afacet_(.*)/))
        field = m[1]
        value = single_param(key)
        if ALLOWED_FACET_FIELDS.include? field
          facet_parser = FacetParameterParser.new(field, value, allowed_return_fields)
          if facet_parser.valid?
            facets[field] = facet_parser.parsed_params
          else
            @errors.concat(facet_parser.errors)
          end
        else
          @errors << %{"#{field}" is not a valid facet field}
        end
        @used_params << key
      end
    end
    facets
  end

  def debug_options
    # Note: this parameter is exposed publically via both the API on GOV.UK and
    # the query parameters for search on GOV.UK.  Don't make it return anything
    # sensitive.
    debug_options = character_separated_param("debug")

    options = {}
    debug_options.each { |option|
      case option
      when ""
      when "disable_best_bets"
        options[:disable_best_bets] = true
      when "disable_popularity"
        options[:disable_popularity] = true
      when "disable_synonyms"
        options[:disable_synonyms] = true
      when "new_weighting"
        options[:new_weighting] = true
      when "explain"
        options[:explain] = true
      else
        @errors << %{Unknown debug option "#{option}"}
      end
    }
    options
  end
end

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
