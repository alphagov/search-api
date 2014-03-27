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
  ALLOWED_FILTER_FIELDS = %w(organisations section)

  def initialize(start, count, query, order, filters, fields)
    @start = start
    @count = count
    @query = query
    @order = order
    @filters = filters
    @fields = fields
  end

  def payload
    Hash[{
      from: @start,
      size: @count,
      query: query_hash,
      filter: filters_hash,
      fields: fields_list,
      sort: sort_list,
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

  def query_hash
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

  def filters_hash
    filter_groups = @filters.map do |field, filter_values|
      unless ALLOWED_FILTER_FIELDS.include? field
        raise ArgumentError, "Filtering by \"#{field}\" is not allowed"
      end
      terms_filter(field, filter_values)
    end
    sort_fields.each do |field|
      filter_groups << {"exists" => {"field" => field}}
    end

    if filter_groups.length == 0
      nil
    elsif filter_groups.length == 1
      filter_groups.first
    else
      {"and" => filter_groups}
    end
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
    return [{ field => { order: dir } }]
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
end
