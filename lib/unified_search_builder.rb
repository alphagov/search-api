require "unf"

# Builds a query for a search across all GOV.UK indices
class UnifiedSearchBuilder

  def initialize(params)
    @params = params
  end

  def payload
    Hash[{
      from: @params[:start],
      size: @params[:count],
      query: query_hash,
      filter: filters_hash,
      fields: @params[:return_fields],
      sort: sort_list,
      facets: facets_hash,
    }.reject{ |key, value|
      [nil, [], {}].include?(value)
    }]
  end

  def query_normalized()
    if @params[:query].nil?
      return nil
    end
    # Put the query into NFKC-normal form to ensure that accent handling works
    # correctly in elasticsearch.
    normalizer = UNF::Normalizer.instance
    query = normalizer.normalize(@params[:query], :nfkc).strip
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
    filter_groups = @params[:filters].reject { |field, filter_values|
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
    order = @params[:order]
    if order.nil?
      return []
    end
    [order[0]]
  end

  # Get a list describing the sort order (or nil)
  def sort_list
    order = @params[:order]
    if order.nil?
      return nil
    end
    [{ order[0] => { order: order[1] } }]
  end

  def facets_hash
    facets = @params[:facets]
    if facets.nil?
      return nil
    end
    result = {}
    facets.each do |field_name, count|
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
