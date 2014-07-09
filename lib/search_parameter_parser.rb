class BaseParameterParser

  # The fields listed here are the only ones which the search results can be
  # ordered by.  These are listed and validated explicitly because
  # sorting by arbitrary fields can be expensive in terms of memory usage in
  # elasticsearch, and because elasticsearch gives fairly obscure error
  # messages if undefined sort fields are used.
  ALLOWED_SORT_FIELDS = %w(
    public_timestamp
  )

  # The fields listed here are the only ones which can be used to filter by.
  ALLOWED_FILTER_FIELDS = %w(
    document_type
    format
    organisations
    section
    specialist_sectors
  )

  # Incoming filter fields will have their names transformed according to the
  # following mapping. Fields not listed here will be passed through unchanged.
  FILTER_NAME_MAPPING = {
    "document_type" => "_type",
  }

  # The fields listed here are the only ones which can be used to calculated
  # facets for.  This should be a subset of ALLOWED_FILTER_FIELDS
  ALLOWED_FACET_FIELDS = %w(
    format
    organisations
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
    organisations
    section
    specialist_sectors
  )

  # The fields listed here are the only ones that can be returned in search
  # results.  These are listed and validated explicitly, rather than simply
  # allowing any field in the schema, to keep the set of such fields as minimal
  # as possible.  This lets us reorganise the way other fields are stored and
  # indexed without having to check that we don't break the display of search
  # results.
  ALLOWED_RETURN_FIELDS = %w(
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

  # The fields which are returned by default for facet examples.
  DEFAULT_FACET_EXAMPLE_FIELDS = %w(
    link
    title
  )

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

  def integer_param(param_name, default, description="")
    value = @params[param_name]
    @used_params << param_name
    unless value.nil?
      value = parse_positive_integer(value, %{parameter "#{param_name}"#{description}})
    end
    if value.nil?
      return default
    end
    value
  end

  def string_param(param_name)
    @used_params << param_name
    @params[param_name]
  end
end

class SearchParameterParser < BaseParameterParser
  def initialize(params)
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
      start: integer_param("start", 0),
      count: integer_param("count", 10),
      query: string_param("q"),
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

  # Get the order for search results to be returned in.
  def order
    order = string_param("order")
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
    return [field, dir]
  end

  # Get a list of the fields to request in results from elasticsearch
  def return_fields
    fields = string_param("fields")
    if fields.nil?
      return DEFAULT_RETURN_FIELDS
    end
    disallowed_fields = fields - ALLOWED_RETURN_FIELDS
    fields = fields - disallowed_fields

    if disallowed_fields.any?
      @errors << "Some requested fields are not valid return fields: #{disallowed_fields}"
    end
    fields
  end

  def filters
    filters = {}
    @params.each do |key, value|
      if (m = key.match(/\Afilter_(.*)/))
        field = m[1]
        if ALLOWED_FILTER_FIELDS.include? field
          filters[filter_name_lookup(field)] = [*value]
        else
          @errors << %{"#{field}" is not a valid filter field}
        end
        @used_params << key
      end
    end
    filters
  end

  def filter_name_lookup(name)
    FILTER_NAME_MAPPING.fetch(name, name)
  end

  def facets
    facets = {}
    @params.each do |key, value|
      if (m = key.match(/\Afacet_(.*)/))
        field = m[1]
        if ALLOWED_FACET_FIELDS.include? field
          facet_parser = FacetParameterParser.new(field, value)
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
    debug = @params["debug"] || ""
    @used_params << "debug"

    options = {}
    debug.split(",").each { |option|
      case option
      when ""
      when "disable_best_bets"
        options[:disable_best_bets] = true
      when "disable_popularity"
        options[:disable_popularity] = true
      when "disable_synonyms"
        options[:disable_synonyms] = true
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
  attr_reader :parsed_params, :errors

  def initialize(field, value)
    @field = field
    process(value)
  end

private

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
      examples: examples,
      example_fields: example_fields,
      example_scope: example_scope,
    }

    if @parsed_params[:examples] > 0 && @parsed_params[:example_scope] != :global
      # global scope means that examples are looked up for each facet value
      # across the whole collection, not just for documents matching the query.
      # This is likely to be a surprising default, so we require that callers
      # explicitly ask for it.
      @errors << %{example_scope parameter must currently be set to global when requesting examples}
      @parsed_params[:examples] = 0
    end

    unused_params = @params.keys - @used_params
    unless unused_params.empty?
      @errors << %{Unexpected options for facet #{@field}: #{unused_params.join(', ')}}
    end
  end

  def parse_options_into_hash(values)
    params = {}
    values.each do |value|
      k_v = value.split(":", 2)
      if k_v.length == 2
        params[k_v[0]] = k_v[1]
      else
        @errors << %{Invalid parameter "#{value}" for facet "#{@field}; must be of form "key:value"}
      end
    end
    params
  end

  def examples
    value = integer_param("examples", 0, %{ in facet "#{@field}"})
    if value != 0
      unless ALLOWED_FACET_EXAMPLE_FIELDS.include? @field
        @errors << %{Facet examples are not supported for field "#{@field}"}
        value = 0
      end
    end
    value
  end

  def example_fields
    fields_str = string_param("example_fields")
    if fields_str.nil?
      return DEFAULT_FACET_EXAMPLE_FIELDS 
    end
    fields = fields_str.split(":")
    disallowed_fields = fields - ALLOWED_RETURN_FIELDS
    fields = fields - disallowed_fields

    if disallowed_fields.any?
      @errors << %{Some requested fields are not valid return fields: #{disallowed_fields} in parameter "example_fields" in facet "#{@field}"}
    end
    fields
  end

  def example_scope
    scope = string_param("example_scope")
    if scope == "global"
      :global
    else
      nil
    end
  end
end
