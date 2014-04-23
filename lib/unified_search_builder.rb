require "elasticsearch/escaping"
require "unf"

# Builds a query for a search across all GOV.UK indices
class UnifiedSearchBuilder
  include Elasticsearch::Escaping

  DEFAULT_QUERY_ANALYZER = "query_default"
  GOVERNMENT_BOOST_FACTOR = 0.4

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

  def query_normalized
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
    @query = query_normalized
    if @query.nil?
      return { match_all: {} }
    end
    {
      custom_filters_score: {
        query: {
          bool: {
            should: [core_query, promoted_items_query].compact
          }
        },
        filters: format_boosts + [time_boost]
      }
    }
  end

  def query_hash
    query = filtered_query
    {
      indices: {
        indices: [:government],
        query: {
          custom_boost_factor: {
            query: query,
            boost_factor: GOVERNMENT_BOOST_FACTOR
          }
        },
        no_match_query: query
      }
    }
  end

  def filtered_query
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

  def core_query
    {
      bool: {
        must: must_conditions,
        should: should_conditions
      }
    }
  end

  def should_conditions
    exact_field_boosts + [ exact_match_boost, shingle_token_filter_boost ]
  end

  def exact_field_boosts
    match_fields.map {|field_name, _|
      {
        match_phrase: {
          field_name => {
            query: escape(@query),
            analyzer: DEFAULT_QUERY_ANALYZER,
          }
        }
      }
    }
  end

  def exact_match_boost
    {
      multi_match: {
        query: escape(@query),
        operator: "and",
        fields: match_fields.keys,
        analyzer: DEFAULT_QUERY_ANALYZER
      }
    }
  end

  def shingle_token_filter_boost
    {
      multi_match: {
        query: escape(@query),
        operator: "or",
        fields: match_fields.keys,
        analyzer: "shingled_query_analyzer"
      }
    }
  end

  def promoted_items_query
    {
      query_string: {
        default_field: "promoted_for",
        query: escape(@query),
        boost: 100
      }
    }
  end

  def query_string_query
    {
      match: {
        _all: {
          query: escape(@query),
          analyzer: DEFAULT_QUERY_ANALYZER,
          minimum_should_match: minimum_should_match
        }
      }
    }
  end

  def minimum_should_match
    # The following specification generates the following values for minimum_should_match
    #
    # Number of | Minimum
    # optional  | should
    # clauses   | match
    # ----------+---------
    # 1         | 1
    # 2         | 2
    # 3         | 2
    # 4         | 3
    # 5         | 3
    # 6         | 3
    # 7         | 3
    # 8+        | 50%
    #
    # This table was worked out by using the comparison feature of
    # bin/search with various example queries of different lengths (3, 4, 5,
    # 7, 9 words) and inspecting the consequences on search results.
    #
    # Reference for the minimum_should_match syntax:
    # http://lucene.apache.org/solr/api-3_6_2/org/apache/solr/util/doc-files/min-should-match.html
    #
    # In summary, a clause of the form "N<M" means when there are MORE than
    # N clauses then M clauses should match. So, 2<2 means when there are
    # MORE than 2 clauses then 2 should match.
    "2<2 3<3 7<50%"
  end

  def must_conditions
    [query_string_query].compact
  end

  def match_fields
    {
      "title" => 5,
      "acronym" => 5, # Ensure that organisations rank brilliantly for their acronym
      "description" => 2,
      "indexable_content" => 1,
    }
  end

  def boosted_formats
    {
      # Mainstream formats
      "smart-answer"      => 1.5,
      "transaction"       => 1.5,
      # Inside Gov formats
      "topical_event"     => 1.5,
      "minister"          => 1.7,
      "organisation"      => 2.5,
      "topic"             => 1.5,
      "document_series"   => 1.3,
      "document_collection" => 1.3,
      "operational_field" => 1.5,
    }
  end

  def format_boosts
    boosted_formats.map do |format, boost|
      {
        filter: { term: { format: format } },
        boost: boost
      }
    end
  end

  # An implementation of http://wiki.apache.org/solr/FunctionQuery#recip
  # Curve for 2 months: http://www.wolframalpha.com/share/clip?f=d41d8cd98f00b204e9800998ecf8427e5qr62u0si
  #
  # Behaves as a freshness boost for newer documents with a public_timestamp and search_format_types announcement
  def time_boost
    {
      filter: { term: { search_format_types: "announcement" } },
      script: "((0.05 / ((3.16*pow(10,-11)) * abs(time() - doc['public_timestamp'].date.getMillis()) + 0.05)) + 0.12)"
    }
  end

end
