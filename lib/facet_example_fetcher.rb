# Fetch example values for facets
class FacetExampleFetcher
  def initialize(index, es_response, params)
    @index = index
    @response_facets = es_response["facets"]
    @params = params
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
  # Fetch facet examples for a given field
  def fetch_for_field(field_name, facet_params)
    example_count = facet_params[:examples]
    example_fields = facet_params[:example_fields]

    facet_options = @response_facets.fetch(field_name, {}).fetch("terms", [])

    slugs = facet_options.map { |option|
      option["term"]
    }
    if slugs.empty?
      {}
    else
      fetch_by_slug(field_name, slugs, example_count, example_fields)
    end
  end

  def facet_example_searches(field_name, slugs, example_count, example_fields)
    slugs.map { |slug|
      {
        query: {
          filtered: {
            filter: { term: { field_name => slug } },
          }
        },
        size: example_count,
        fields: example_fields,
        sort: [ { popularity: { order: :desc } } ],
      }
    }
  end

  # Fetch facet examples for a set of slugs
  def fetch_by_slug(field_name, slugs, example_count, example_fields)
    searches = facet_example_searches(field_name, slugs, example_count, example_fields)
    responses = @index.msearch(searches)
    response_list = responses["responses"]
    result = {}
    slugs.zip(response_list) { |slug, response|
      hits = response["hits"]
      result[slug] = {
        total: hits["total"],
        examples: hits["hits"].map { |hit| hit["fields"] },
      }
    }
    result
  end
end
