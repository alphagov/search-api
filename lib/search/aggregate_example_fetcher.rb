module Search
  class AggregateExampleFetcher
    attr_reader :search_params

    def initialize(index, es_response, search_params, query_builder)
      @index = index
      @response_aggregates = es_response["aggregations"]
      @search_params = search_params
      @query_builder = query_builder
    end

    # Fetch all requested example aggregate values
    # Returns {field_name => {aggregate_value => {total: count, examples: [{field: value}, ...]}}}
    # ie: a hash keyed by field name, containing hashes keyed by aggregate value with
    # values containing example information for the value.
    def fetch(slugs_for_field)
      return {} if @response_aggregates.nil?

      search_params.aggregates.reduce({}) do |result, (field_name, aggregate_params)|
        if aggregate_params[:examples].positive?
          result[field_name] = fetch_for_field(field_name, aggregate_params, slugs_for_field[field_name])
        end
        result
      end
    end

  private

    def field_definitions
      @index.schema.field_definitions
    end

    def fetch_for_field(field_name, aggregate_params, slugs)
      example_count = aggregate_params[:examples]
      example_fields = aggregate_params[:example_fields]
      scope = aggregate_params[:example_scope]

      if scope == :query
        query = @query_builder.query
        filter = @query_builder.filter
      else
        query = nil
        filter = Search::FormatMigrator.new(search_params.search_config).call
      end

      if slugs.nil?
        {}
      else
        batched_fetch_by_slug(field_name, slugs, example_count, example_fields, query, filter)
      end
    end

    def aggregate_example_searches(field_name, slugs, example_count, example_fields, query, query_filter)
      slugs.map { |slug|
        if query_filter.nil?
          filter = { term: { field_name => slug } }
        else
          filter = [
            { term: { field_name => slug } },
            query_filter,
          ]
        end
        {
          query: {
            bool: {
              must: query,
            },
          },
          post_filter: { bool: { must: filter } },
          size: example_count,
          _source: {
            includes: example_fields,
          },
          sort: [{ popularity: { order: :desc } }],
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

    # Fetch aggregate examples for a set of slugs
    def fetch_by_slug(field_name, slugs, example_count, example_fields, query, filter)
      searches = aggregate_example_searches(field_name, slugs, example_count,
                                            example_fields, query, filter)
      responses = @index.msearch(searches)
      response_list = responses["responses"]
      prepare_response(slugs, response_list)
    end

    def prepare_response(slugs, response_list)
      result = {}
      slugs.zip(response_list) { |slug, response|
        result[slug] = {
          total: response["hits"]["total"],
          examples: response["hits"]["hits"].map { |hit| apply_multivalued(hit["_source"] || {}) },
        }
      }

      result
    end

    def apply_multivalued(document_attrs)
      document_attrs.reduce({}) { |result, (field_name, values)|
        if field_name[0] == "_"
          # Special fields are always returned as single values.
          result[field_name] = values
          return result
        end

        # Convert to array for consistency between elasticsearch 0.90 and 1.0.
        # When we no longer support elasticsearch <1.0, values here will
        # always be an array, so this block can be removed.
        if values.nil?
          values = []
        elsif !values.is_a?(Array)
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
end
