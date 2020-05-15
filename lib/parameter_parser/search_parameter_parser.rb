class SearchParameterParser < BaseParameterParser
  VIRTUAL_FIELDS = %w[
    title_with_highlighting
    description_with_highlighting
    expanded_topics
    expanded_organisations
  ].freeze
  MAX_RESULTS = 1500

  # We currently have 375,000 items in Rummager.  Anything over around 900_000
  # results in 5XX errors
  MAX_START = 900_000

  # Reject queries over this length, because such queries are likely
  # bots and have a negative effect on performance.
  MAX_QUERY_LENGTH = 512

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

    # Dummy field that can be used to bypass caching when testing/debugging
    @used_params << "c"

    query = normalize_query(single_param("q"), "query")
    @parsed_params = {
      start: capped_start,
      count: capped_count,
      cluster: cluster,
      search_config: SearchConfig.instance(cluster),
      query: query,
      parsed_query: parse_query(query),
      similar_to: normalize_query(single_param("similar_to"), "similar_to"),
      order: order,
      return_fields: return_fields,
      filters: filters,
      aggregates: aggregates,
      aggregate_name: @aggregate_name,
      debug: debug_options,
      suggest: character_separated_param("suggest"),
      ab_tests: ab_tests,
    }

    # Search can be run either with a text query or a base_path to find
    # similar documents, but not both at the same time.
    if @parsed_params[:query] && @parsed_params[:similar_to]
      @errors << "Parameters 'q' and 'similar_to' cannot be used together"
    end

    if @parsed_params[:query] && @parsed_params[:query].length > MAX_QUERY_LENGTH
      @errors << "Query exceeds the maximum allowed length"
    end

    unused_params = @params.keys - @used_params
    unless unused_params.empty?
      @errors << "Unexpected parameters: #{unused_params.join(', ')}"
    end
  end

  def cluster
    @cluster ||= Clusters.default_cluster
  end

  def capped_start
    specified_start = single_integer_param("start", 0)
    if specified_start > MAX_START
      @errors << "Maximum result set start point (as specified in 'start') is #{MAX_START}"
      0
    else
      specified_start
    end
  end

  def capped_count
    specified_count = single_integer_param("count", 10)
    if specified_count > MAX_RESULTS
      @errors << "Maximum result set size (as specified in 'count') is #{MAX_RESULTS}"
      10
    else
      specified_count
    end
  end

  def parse_query(query)
    return nil if query.nil?

    quoted = []
    unquoted = []

    current_keyword = ""
    is_inside_quote = false
    query.split("").each do |c|
      if c == '"'
        current_keyword = current_keyword.strip
        if is_inside_quote
          quoted << current_keyword unless current_keyword.empty?
        else
          unquoted << current_keyword unless current_keyword.empty?
        end
        is_inside_quote = !is_inside_quote
        current_keyword = ""
      else
        current_keyword << c
      end
    end

    # treats an unterminated quote as an unquoted phrase
    current_keyword = current_keyword.strip
    unquoted << current_keyword unless current_keyword.empty?

    {
      unquoted: unquoted.join(" "),
      quoted: quoted,
    }
  end

  def normalize_query(query, description)
    unless query.nil?
      query = normalize_unicode(query, description)
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

  def normalize_unicode(string, description)
    normalizer = UNF::Normalizer.instance
    begin
      # Put strings into NFKC-normal form to ensure that accent handling works
      # correctly in elasticsearch.
      normalizer.normalize(string, :nfkc).strip
    rescue ArgumentError
      @errors << %(Invalid unicode in #{description})
      nil
    end
  end

  # Get the order for search results to be returned in.
  def order
    order = single_param("order")
    similar_to = @params["similar_to"]
    if order.nil? || !similar_to.nil?
      # If "similar_to" is defined then "order" is always nil, since
      # searches for "similar" documents are already sorted by "similarity" by
      # elasticsearch.
      return nil
    end

    if order.start_with?("-")
      field = order[1..-1]
      dir = "desc"
    else
      field = order
      dir = "asc"
    end
    unless ALLOWED_SORT_FIELDS.include?(field)
      @errors << %("#{field}" is not a valid sort field)
      return nil
    end
    [SORT_MAPPINGS.fetch(field, field), dir]
  end

  # Get a list of the fields to request in results from elasticsearch
  def return_fields
    fields = character_separated_param("fields")
    if fields.empty?
      return DEFAULT_RETURN_FIELDS
    end

    disallowed_fields = fields - allowed_return_fields
    fields -= disallowed_fields

    if disallowed_fields.any?
      @errors << "Some requested fields are not valid return fields: #{disallowed_fields}"
    end
    fields
  end

  def validate_filter_parameters(parameter_hashes)
    allowed, disallowed = parameter_hashes.partition do |parameter_hash|
      allowed_filter_fields.include?(parameter_hash["name"])
    end

    disallowed.each do |parameter_hash|
      @errors << %("#{parameter_hash['name']}" is not a valid #{parameter_hash['operation']} field)
    end

    allowed
  end

  # Returns hashes of
  #   {'operation'=> 'filter/reject',
  #    'multivalue_query' => 'any/all',
  #    'name'=>'...',
  #    'full_name'=>'...',
  #    'values'=>[...]}
  def analyze_filters(parameters)
    matches = parameters.keys.map do |name|
      /^(?'full_name'(?'operation'filter|reject)_(?:(?'multivalue_query'any|all)_)?(?'name'.*))$/.match(name)
    end
    matches.compact.map do |match|
      captures = match.named_captures
      full_name = captures["full_name"]
      captures.merge({ "values" => parameters[full_name] })
    end
  end

  def filters
    filter_hashes = analyze_filters(@params)

    @used_params.concat(filter_hashes.map { |h| h["full_name"] })

    validated_hashes = validate_filter_parameters(filter_hashes)
    result = validated_hashes.map do |hash|
      build_filter(
        filter_name_lookup(hash["name"]),
        hash.fetch("values"),
        hash.fetch("operation").to_sym,
        (hash.fetch("multivalue_query") || "any").to_sym,
      )
    end
    result.compact
  end

  def allowed_filter_fields
    # `document_type` & `elasticsearch_type` are aliases for the internal
    # "document_type" field.
    # TODO: Clients should not use this `document_type`.
    %w[document_type elasticsearch_type] + @schema.allowed_filter_fields
  end

  def allowed_return_fields
    @schema.field_definitions.keys + VIRTUAL_FIELDS
  end

  def build_filter(field_name, values, operation, multivalue_query)
    if field_name == "document_type"
      filter_type = "text"
    else
      filter_type = @schema.field_definitions.fetch(field_name).type.filter_type
    end

    if filter_type.nil?
      @errors << %("#{field_name}" has no filter_type defined)
      return nil
    end

    filter_class = {
      "text" => TextFieldFilter,
      "date" => DateFieldFilter,
      "boolean" => BooleanFieldFilter,
    }.fetch(filter_type)

    filter = filter_class.new(field_name, values, operation, multivalue_query)
    if filter.valid?
      filter
    else
      @errors.concat(filter.errors)
      nil
    end
  end

  class Filter
    attr_reader :field_name, :include_missing, :values, :operation, :multivalue_query, :errors

    # operation is :reject or :filter
    # multivalue_query is :all or :any
    def initialize(field_name, values, operation, multivalue_query)
      @field_name = field_name
      @include_missing = values.include? BaseParameterParser::MISSING_FIELD_SPECIAL_VALUE
      @values = Array(values).reject { |value| value == BaseParameterParser::MISSING_FIELD_SPECIAL_VALUE }
      @operation = operation
      @multivalue_query = multivalue_query
      @errors = []
    end

    def type
      raise NotImplementedError
    end

    def ==(other)
      [field_name, values, operation, multivalue_query] == [other.field_name, other.values, other.operation, other.multivalue_query]
    end

    def valid?
      errors.empty?
    end
  end

  class DateFieldFilter < Filter
    DATE_PATTERN = /^\d{4}-\d{2}-\d{2}$/.freeze

    def initialize(field_name, values, operation, multivalue_query)
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

      values.map do |combined_from_and_to|
        dates_hash = combined_from_and_to.split(",").reduce({}) do |dates, param|
          key, date = param.split(":", 2)
          validate_date_key(key)
          dates.merge(key => parse_date(key, date))
        end

        Value.new(
          dates_hash.fetch("from", null_date),
          dates_hash.fetch("to", null_date),
        )
      end
    end

    def validate_date_key(key)
      unless %w[from to].include?(key)
        @errors << %{Invalid date filter parameter "#{key}:" (expected "from:" or "to:")}
      end
    end

    def parse_date(label, date_string)
      date = DateTime.parse(date_string)

      if DATE_PATTERN.match(date_string) && label == "to"
        end_of_day(date)
      else
        date
      end
    rescue StandardError
      @errors << %{Invalid "#{label}" value "#{date_string}" for parameter "#{field_name}" (expected ISO8601 date)}
      null_date
    end

    def end_of_day(date)
      DateTime.new(date.year, date.month, date.day, 23, 59, 59)
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

  class BooleanFieldFilter < Filter
    def initialize(field_name, values, operation, multivalue_query)
      super
      @values = parse_bool(values, field_name)
    end

    def type
      "boolean"
    end

  private

    def parse_bool(values, field_name)
      values.map do |value|
        if %w[true false].include?(value)
          value
        else
          @errors << %{#{field_name} requires a boolean (true or false)}
          "false"
        end
      end
    end
  end

  def filter_name_lookup(name)
    FILTER_NAME_MAPPING.fetch(name, name)
  end

  def aggregates
    parser = AggregatesParameterParser.new(@params, allowed_return_fields)
    parser.call

    @errors += parser.errors
    @used_params += parser.used_params
    @aggregate_name = (parser.aggregate_name || "aggregates").pluralize.to_sym
    parser.aggregates
  end

  def debug_options
    # Note: this parameter is exposed publically via both the API on GOV.UK and
    # the query parameters for search on GOV.UK.  Don't make it return anything
    # sensitive.
    debug_options = character_separated_param("debug")

    options = {}

    debug_options.each do |option|
      case option
      when "disable_best_bets"
        options[:disable_best_bets] = true
      when "disable_popularity"
        options[:disable_popularity] = true
      when "disable_synonyms"
        options[:disable_synonyms] = true
      when "disable_boosting"
        options[:disable_boosting] = true
      when "explain"
        options[:explain] = true
      when "include_withdrawn"
        # Withdrawn content is excluded from regular searches but is useful for
        # content audits
        options[:include_withdrawn] = true
      when "show_query"
        options[:show_query] = true
      else
        @errors << %(Unknown debug option "#{option}") unless option.blank?
      end
    end

    options
  end

  def ab_tests
    @ab_tests ||=
      begin
        variants = character_separated_param("ab_tests")
        variants = variants.map { |variant| variant.split(":", 2) }

        variants.each_with_object({}) do |(variant_name, variant_code), variants_hash|
          if variant_code.blank?
            @errors << %(Invalid ab_tests, missing type "#{variant_name}")
          end
          variants_hash[variant_name.to_sym] = variant_code
        end
      end
  end
end
