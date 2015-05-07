# Fetch example values for facets
class FacetExampleFetcher
  def initialize(index, es_response, params, search_builder)
    @index = index
    @response_facets = es_response["facets"]
    @params = params
    @search_builder = search_builder
  end

  # Fetch all requested example facet values
  # Returns {field_name => {facet_value => {total: count, examples: [{field: value}, ...]}}}
  # ie: a hash keyed by field name, containing hashes keyed by facet value with
  # values containing example information for the value.
  def fetch
    facets = @params[:facets]
    if facets.nil? || @response_facets.nil?
      return {}
    end
    result = {}
    facets.each do |field_name, facet_params|
      examples = facet_params[:examples]
      if examples > 0
        result[field_name] = fetch_for_field(field_name, facet_params)
      end
    end
    result
  end

private

  def field_definitions
    @index.schema.field_definitions
  end

  def fetch_for_field(field_name, facet_params)
    example_count = facet_params[:examples]
    example_fields = facet_params[:example_fields]
    scope = facet_params[:example_scope]

    if scope == :query
      query = @search_builder.query
      filter = @search_builder.filter
    else
      query = nil
      filter = nil
    end

    facet_options = @response_facets.fetch(field_name, {}).fetch("terms", [])

    slugs = facet_options.map { |option|
      option["term"]
    }
    if slugs.empty?
      {}
    else
      batched_fetch_by_slug(field_name, slugs, example_count, example_fields, query, filter)
    end
  end

  def facet_example_searches(field_name, slugs, example_count, example_fields, query, query_filter)
    slugs.map { |slug|
      if query_filter.nil?
        filter = { term: { field_name => slug } }
      else
        filter = { and: [
          { term: { field_name => slug } },
          query_filter,
        ]}
      end
      {
        query: {
          filtered: {
            query: query,
            filter: filter,
          }
        },
        size: example_count,
        fields: example_fields,
        sort: [ { popularity: { order: :desc } } ],
      }
    }
  end

  def batched_fetch_by_slug(field_name, slugs, example_count, example_fields, query, filter)
    # Elasticsearch has an internal queue limit on the number of searches to be
    # performed: this defaults to 1000.  If we go close to this limit, we risk
    # getting error responses saying that the queue is full.  Therefore,
    # instead of sending all the searches at once, we send them in batches of
    # 50.

    some_results = slugs.each_slice(50).map { |fewer_slugs|
      fetch_by_slug(field_name, fewer_slugs, example_count, example_fields, query, filter)
    }
    some_results.reduce(&:merge)
  end

  # Fetch facet examples for a set of slugs
  def fetch_by_slug(field_name, slugs, example_count, example_fields, query, filter)
    searches = facet_example_searches(field_name, slugs, example_count,
                                      example_fields, query, filter)
    responses = @index.msearch(searches)
    response_list = responses["responses"]
    result = {}
    slugs.zip(response_list) { |slug, response|
      hits = response["hits"]
      result[slug] = {
        total: hits["total"],
        examples: hits["hits"].map { |hit| apply_multivalued(hit["fields"]) },
      }
    }
    result
  end

  def apply_multivalued(document_attrs)
    document_attrs.reduce({}) { |result, (field_name, values)|
      if field_name[0] == '_'
        # Special fields are always returned as single values.
        result[field_name] = values
        return result
      end

      # Convert to array for consistency between elasticsearch 0.90 and 1.0.
      # When we no longer support elasticsearch <1.0, values here will
      # always be an array, so this block can be removed.
      if values.nil?
        values = []
      elsif !(values.is_a?(Array))
        values = [values]
      end

      if field_definitions.fetch(field_name).type.multivalued
        result[field_name] = values
      else
        result[field_name] = values.first
      end
      result
    }
  end
end
