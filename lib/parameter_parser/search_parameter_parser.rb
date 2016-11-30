require_relative "base_parameter_parser"

class SearchParameterParser < BaseParameterParser
  VIRTUAL_FIELDS = %w[
    title_with_highlighting
    description_with_highlighting
    expanded_topics
    expanded_organisations
  ].freeze
  MAX_RESULTS = 1000

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
      count: capped_count,
      query: normalize_query(single_param("q")),
      order: order,
      return_fields: return_fields,
      filters: filters,
      facets: facets,
      debug: debug_options,
      suggest: character_separated_param("suggest"),
    }

    unused_params = @params.keys - @used_params
    unless unused_params.empty?
      @errors << "Unexpected parameters: #{unused_params.join(', ')}"
    end
  end

  def capped_count
    specified_count = single_integer_param("count", 10)
    if specified_count > MAX_RESULTS
      @errors << "Maximum result set size (as specified in 'count') is #{MAX_RESULTS}"
      return 10
    else
      specified_count
    end
  end

  def normalize_query(query)
    unless query.nil?
      query = normalize_unicode(query, "query")
    end
    unless query.nil?
      query = query.strip
      if query.empty?
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
    [SORT_MAPPINGS.fetch(field, field), dir]
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
    with_prefix = @params.select do |name, _|
      name.start_with?(prefix)
    end

    with_prefix.each_with_object({}) do |(name, value), result|
      @used_params << name
      result[name.sub(prefix, "")] = value
    end
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
    # `document_type` & `elasticsearch_type` are aliases for the internal
    # "_type" field.
    # TODO: Clients should not use this `document_type`.
    %w[document_type elasticsearch_type] + @schema.allowed_filter_fields
  end

  def allowed_return_fields
    @schema.field_definitions.keys + VIRTUAL_FIELDS
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
    @params.each do |key, _values|
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

    debug_options.each do |option|
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
      when "include_withdrawn"
        # Withdrawn content is excluded from regular searches but is useful for
        # content audits
        options[:include_withdrawn] = true
      when "use_id_codes"
        options[:use_id_codes] = true
      when "show_query"
        options[:show_query] = true
      else
        @errors << %{Unknown debug option "#{option}"}
      end
    end

    options
  end
end
