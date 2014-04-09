require "unf"

# Builds a query for a search across all GOV.UK indices
class UnifiedSearchBuilder

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

  def initialize(start, count, query, order, filters, fields, facet_fields)
    @start = start
    @count = count
    @query = query
    @order = order
    @filters = filters
    @fields = fields
    @facet_fields = facet_fields
  end

  def payload
    Hash[{
      from: @start,
      size: @count,
      query: query_hash,
      filter: filters_hash,
      fields: fields_list,
      sort: sort_list,
      facets: facets_hash,
    }.select{ |key, value|
      ![nil, [], {}].include?(value)
    }]
  end

  def query_normalized()
    if @query.nil?
      return nil
    end
    normalizer = UNF::Normalizer.instance
    query = normalizer.normalize(@query, :nfkc).strip
    if query.length == 0
      return nil
    end
    query
  end

  def base_query
    query = query_normalized
    if query.nil?
      return { match_all: {} }
    end
    {
      match: {
        _all: {
          query: query
        }
      }
    }
  end

  def query_hash
    filter = sort_filters
    if filter.nil?
      base_query
    else
      {
        filtered: {
          filter: filter,
          query: base_query,
        }
      }
    end
  end

  def combine_filters(filters)
    if filters.length == 0
      nil
    elsif filters.length == 1
      filters.first
    else
      {"and" => filters}
    end
  end

  def sort_filters
    # Filters to ensure that fields being sorted by exist.
    combine_filters(
      sort_fields.map { |field|
        {"exists" => {"field" => field}}
      }
    )
  end

  def filters_hash(excluding=[])
    disallowed_fields = @filters.keys - ALLOWED_FILTER_FIELDS
    unless disallowed_fields.empty?
      raise ArgumentError, "Filtering by \"#{disallowed_fields.join(', ')}\" is not allowed"
    end

    filter_groups = @filters.reject { |field, filter_values|
      excluding.include? field
    }.map { |field, filter_values|
      terms_filter(field, filter_values)
    }

    # Don't add additional filters to filter_groups without making sure that
    # the facet_filter values used in facets include the filter too.  It's
    # usually better to add additional filters to the query, so that they
    # automatically apply to facet calculation.
    combine_filters(filter_groups)
  end

  def terms_filter(field, filter_values)
    {"terms" => { field => filter_values } }
  end

  # Get a list of fields being sorted by
  def sort_fields
    if @order.nil?
      return []
    end
    if @order.start_with?('-')
      return [@order[1..-1]]
    else
      return [@order]
    end
  end
 
  # Get a list describing the sort order (or nil)
  def sort_list
    if @order.nil?
      return nil
    end
    if @order.start_with?('-')
      field = @order[1..-1]
      dir = "desc"
    else
      field = @order
      dir = "asc"
    end
    unless ALLOWED_SORT_FIELDS.include?(field)
      raise ArgumentError, "Sorting by \"#{field}\" is not allowed"
    end
    [{ field => { order: dir } }]
  end

  # Get a list of the fields to request in results from elasticsearch
  def fields_list
    if @fields.nil?
      return ALLOWED_RETURN_FIELDS
    end
    disallowed_fields = @fields - ALLOWED_RETURN_FIELDS
    unless disallowed_fields.empty?
      raise ArgumentError, "Requested fields not allowed: #{disallowed_fields}"
    end
    @fields
  end

  def facets_hash
    if @facet_fields.nil?
      return nil
    end
    result = {}
    @facet_fields.each do |field_name, count|
      unless ALLOWED_FACET_FIELDS.include?(field_name)
        raise ArgumentError, "Facets not allowed on field #{field_name}"
      end
      facet_hash = {
        terms: {
          field: field_name,
          order: "count",
          # We want all the facet values so we can return an accurate count of
          # the number of options.  With elasticsearch 0.90+ we can get this by
          # setting size to 0, but at the time of writing we're using 0.20.6,
          # so just have to set a high value for size.
          size: 100000,
        }
      }
      facet_filter = filters_hash([field_name])
      unless facet_filter.nil?
        facet_hash[:facet_filter] = facet_filter
      end
      result[field_name] = facet_hash
    end
    result
  end

end
