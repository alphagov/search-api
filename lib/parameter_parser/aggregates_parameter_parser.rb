class AggregatesParameterParser < BaseParameterParser
  attr_reader :errors, :used_params, :aggregates, :aggregate_name

  def initialize(params, allowed_return_fields)
    @params = params
    @allowed_return_fields = allowed_return_fields

    @aggregates = {}
    @errors = []
    @used_params = []
  end

  def call
    @params.each do |key, _values|
      # to ensure backwards compatibility we will support both facet_* and aggregate_* style naming
      # - all aggregations in the request must use the same naming format
      matches = key.match(/\A(facet|aggregate)_(.*)\Z/)
      next unless matches

      validate_aggregate_naming(matches[1])
      field = matches[2]

      value = single_param(key)
      if ALLOWED_AGGREGATE_FIELDS.include? field
        parse(field, value)
      else
        errors << %("#{field}" is not a valid aggregate field)
      end
    end
  end

private

  def parse(field, value)
    aggregate_parser = AggregateParameterParser.new(field, value, @allowed_return_fields)
    if aggregate_parser.valid?
      aggregates[field] = aggregate_parser.parsed_params
    else
      @errors << aggregate_parser.errors
    end
  end

  def validate_aggregate_naming(aggregate_name)
    @aggregate_name ||= aggregate_name
    if @aggregate_name != aggregate_name
      errors << %(aggregates can not be used in conjuction with facets, please switch to using aggregates as facets are deprecated.)
    end
  end
end
