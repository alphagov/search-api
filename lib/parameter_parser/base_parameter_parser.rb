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
