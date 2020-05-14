class BaseParameterParser
  class ParseError < StandardError
    attr_reader :errors

    def initialize(errors)
      @errors = errors
    end

    def error
      errors.join(". ")
    end
  end

  # The fields listed here are the only ones which the search results can be
  # ordered by.  These are listed and validated explicitly because
  # sorting by arbitrary fields can be expensive in terms of memory usage in
  # elasticsearch, and because elasticsearch gives fairly obscure error
  # messages if undefined sort fields are used.
  ALLOWED_SORT_FIELDS = %w[
    public_timestamp
    closing_date
    title
    tribunal_decision_decision_date
    start_date
    assessment_date
    popularity
    release_timestamp
  ].freeze

  SORT_MAPPINGS = {
    "title" => "title.sort",
  }.freeze

  # Incoming filter fields will have their names transformed according to the
  # following mapping. Fields not listed here will be passed through unchanged.
  FILTER_NAME_MAPPING = {
    # TODO: clients should not use `document_type` to search for documents.
    "document_type" => "document_type",
    "elasticsearch_type" => "document_type",
  }.freeze

  # The fields listed here are the only ones which can be used to calculated
  # aggregates for.  This should be a subset of allowed_filter_fields
  ALLOWED_AGGREGATE_FIELDS = %w[
    content_purpose_document_supertype
    content_purpose_subgroup
    content_purpose_supergroup
    content_store_document_type
    detailed_format
    document_collections
    document_series
    email_document_supertype
    format
    government_document_supertype
    mainstream_browse_pages
    manual
    navigation_document_supertype
    organisation_type
    organisations
    part_of_taxonomy_tree
    people
    policies
    policy_areas
    primary_publishing_organisation
    publishing_app
    rendering_app
    roles
    search_format_types
    search_user_need_document_supertype
    specialist_sectors
    taxons
    topical_events
    user_journey_document_supertype
    world_locations
  ].freeze

  # The fields for which aggregates examples are allowed to be requested.
  # This is locked down because these can only be requested with the current
  # version of elasticsearch by performing a separate query for each aggregates
  # option. This is done using the msearch API to perform many queries
  # together, but is still potentially expensive. They could be efficiently
  # calculated with the top-documents aggregator in elasticsearch 1.3, so this
  # restriction could be relaxed in future.
  ALLOWED_AGGREGATE_EXAMPLE_FIELDS = %w[
    content_store_document_type
    content_purpose_subgroup
    content_purpose_supergroup
    email_document_supertype
    format
    government_document_supertype
    mainstream_browse_pages
    manual
    navigation_document_supertype
    organisations
    part_of_taxonomy_tree
    publishing_app
    rendering_app
    specialist_sectors
    taxons
    topical_events
  ].freeze

  # The keys by which aggregates values can be sorted (using the "order" option).
  # Multiple can be supplied, separated by colons - items which are equal
  # according to the first option are sorted by the next key, etc.  keys can be
  # preceded with a "-" to sort in descending order.
  #  - filtered: sort fields which have filters applied to them first.
  #  - count: sort values by number of matching documents.
  #  - value: sort by value if string, sort by title if not a string
  #  - value.slug: sort values by the slug part of the value.
  #  - value.title: sort values by the title of the value.
  #  - value.link: sort values by the link of the value.
  #
  ALLOWED_AGGREGATE_SORT_OPTIONS = %w[
    filtered
    count
    value
    value.slug
    value.title
    value.link
  ].freeze

  # Scopes that are allowed when requesting examples for aggregatess
  #  - query: Return only examples that match the query and filters
  #  - global: Return examples for the aggregates regardless of whether they match
  #            the query and filters
  ALLOWED_EXAMPLE_SCOPES = %i[global query].freeze

  # The fields which are returned by default for search results.
  DEFAULT_RETURN_FIELDS = %w[
    description
    display_type
    document_series
    format
    link
    organisations
    public_timestamp
    slug
    specialist_sectors
    title
    policy_areas
    world_locations
    topic_content_ids
    topical_events
    expanded_topics
    organisation_content_ids
    expanded_organisations
  ].freeze

  # Default order in which aggregates results are sorted
  DEFAULT_AGGREGATE_SORT = [
    [:filtered, 1],
    [:count, -1],
    [:slug, 1],
  ].freeze

  # The fields which are returned by default for aggregates examples.
  DEFAULT_AGGREGATE_EXAMPLE_FIELDS = %w[
    link
    title
  ].freeze

  # A special value used to filter for missing fields.
  MISSING_FIELD_SPECIAL_VALUE = "_MISSING".freeze

  attr_reader :parsed_params, :errors

  def valid?
    errors.empty?
  end

  def validate!
    raise ParseError, errors unless valid?
  end

protected

  def parse_positive_integer(value, description)
    begin
      result = Integer(value, 10)
    rescue ArgumentError
      @errors << %{Invalid value "#{value}" for #{description} (expected positive integer)}
      return nil
    end
    if result.negative?
      @errors << %{Invalid negative value "#{value}" for #{description} (expected positive integer)}
      return nil
    end
    result
  end

  # Get a parameter that occurs at most once
  # Returns the string value of the parameter, or nil
  def single_param(param_name, description = "")
    @used_params << param_name
    values = @params.fetch(param_name, [])
    if values.size > 1
      @errors << %{Too many values (#{values.size}) for parameter "#{param_name}"#{description} (must occur at most once)}
    end
    values.first
  end

  # Get a parameter represented as a comma separated list
  # Multiple occurrences of the parameter will be joined together
  def character_separated_param(param_name, separator = ",")
    @used_params << param_name
    values = @params.fetch(param_name, [])
    values.map { |value|
      value.split(separator)
    }.flatten
  end

  # Parse a parameter which should contain an integer and occur only once
  # Returns the integer value, or the provided default
  def single_integer_param(param_name, default, description = "")
    value = single_param(param_name, description)
    return default if value.nil?

    value = parse_positive_integer(value, %(parameter "#{param_name}"#{description}))
    return default if value.nil?

    value
  end
end
