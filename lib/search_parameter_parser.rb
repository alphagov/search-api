class SearchParameterParser

  attr_reader :parsed_params

  # The fields listed here are the only ones which the search results can be
  # ordered by.  These are listed and validated explicitly because
  # sorting by arbitrary fields can be expensive in terms of memory usage in
  # elasticsearch, and because elasticsearch gives fairly obscure error
  # messages if undefined sort fields are used.
  ALLOWED_SORT_FIELDS = %w(public_timestamp)

  # The fields listed here are the only ones which can be used to filter by.
  ALLOWED_FILTER_FIELDS = %w(organisations section format)

  # The fields listed here are the only ones which can be used to calculated
  # facets for.  This should be a subset of ALLOWED_FILTER_FIELDS
  ALLOWED_FACET_FIELDS = %w(organisations section format)

  # The fields listed here are the only ones that can be returned in search
  # results.  These are listed and validated explicitly, rather than simply
  # allowing any field in the schema, to keep the set of such fields as minimal
  # as possible.  This lets us reorganise the way other fields are stored and
  # indexed without having to check that we don't break the display of search
  # results.
  ALLOWED_RETURN_FIELDS = %w(
    title description link slug

    public_timestamp
    organisations topics world_locations document_series

    format display_type
    section subsection subsubsection

  )

  def initialize(params)
    process(params)
  end

  def valid?
    @errors.empty?
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
      return ALLOWED_RETURN_FIELDS
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
          filters[field] = [*value]
        else
          @errors << %{"#{field}" is not a valid filter field}
        end
        @used_params << key
      end
    end
    filters
  end

  def facets
    facets = {}
    @params.each do |key, value|
      if (m = key.match(/\Afacet_(.*)/))
        field = m[1]
        if ALLOWED_FACET_FIELDS.include? field
          count = parse_positive_integer(value, %{facet "#{field}"})
          unless count.nil?
            facets[field] = count
          end
        else
          @errors << %{"#{field}" is not a valid facet field}
        end
        @used_params << key
      end
    end
    facets
  end

  def integer_param(param_name, default)
    value = @params[param_name]
    @used_params << param_name
    unless value.nil?
      value = parse_positive_integer(value, %{parameter "#{param_name}"})
    end
    if value.nil?
      return default
    end
    value
  end

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

  def string_param(param_name)
    @used_params << param_name
    @params[param_name]
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
      when "explain"
        options[:explain] = true
      else
        @errors << %{Unknown debug option "#{option}"}
      end
    }
    options
  end
end
