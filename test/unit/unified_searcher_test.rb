require "test_helper"
require "set"
require "unified_searcher"
require "search_parameter_parser"

class UnifiedSearcherTest < ShouldaUnitTestCase
  EMPTY_ES_RESPONSE = {
    "hits" => { "hits" => {}, "total" => 0 }
  }

  def setup
    Timecop.freeze
    super
  end

  def stub_suggester
    stub('Suggester', suggestions: ['cheese'])
  end

  def text_filter(field_name, values, reject = false)
    SearchParameterParser::TextFieldFilter.new(field_name, values, reject)
  end

  def date_filter(field_name, values, reject = false)
    SearchParameterParser::DateFieldFilter.new(field_name, values, reject)
  end

  def mock_best_bets(query)
    @metasearch_index = stub("metasearch index")
    @metasearch_index.stubs(:raw_search).with(
      {
        query: {:bool => {:should => [{:match => {:exact_query => query}},
                                      {:match => {:stemmed_query => query}}]}},
        size: 1000,
        fields: [:details, :stemmed_query_as_term],
      }, "best_bet").returns(
      {
        "hits" => {"hits" => [], "total" => [].size}
      })
    @metasearch_index.stubs(:analyzed_best_bet_query).with(query).returns(query)
  end

  def make_searcher
    mock_best_bets("cheese")
    UnifiedSearchBuilder.any_instance.stubs query: 'A SUPER LONG QUERY'

    searcher = UnifiedSearcher.new(@combined_index, @metasearch_index, {}, stub_suggester)
    @combined_index.stubs(:schema).returns(make_schema)
    searcher
  end

  def make_schema
    schema = stub("schema")
    index_schema = stub("index schema")

    schema.stubs(:schema_for_alias_name).returns(index_schema)
    schema.stubs(:field_definitions)
    index_schema.stubs(:document_type).returns(sample_document_types["cma_case"])
    schema
  end

  context "unfiltered, unsorted search" do
    should 'call raw_search with the results from the builder' do
      @combined_index = stub("unified index")
      @searcher = make_searcher
      @combined_index.expects(:raw_search).with({
        from: 0,
        size: 20,
        query: 'A SUPER LONG QUERY',
        fields: SearchParameterParser::ALLOWED_RETURN_FIELDS,
      }).returns(EMPTY_ES_RESPONSE)

      @results = @searcher.search({
        start: 0,
        count: 20,
        query: "cheese",
        order: nil,
        filters: {},
        return_fields: SearchParameterParser::ALLOWED_RETURN_FIELDS,
        debug: {},
      })
    end
  end

  context "unfiltered, sorted search" do
    should 'call raw_search with the results from the builder' do
      @combined_index = stub("unified index")
      @searcher = make_searcher
      @combined_index.stubs(:raw_search).with({
        from: 0,
        size: 20,
        query: 'A SUPER LONG QUERY',
        fields: SearchParameterParser::ALLOWED_RETURN_FIELDS,
        sort: [{"public_timestamp" => {order: "asc", missing: "_last"}}],
      }).returns(EMPTY_ES_RESPONSE)

      @results = @searcher.search({
        start: 0,
        count: 20,
        query: "cheese",
        order: ["public_timestamp", "asc"],
        filters: {},
        return_fields: SearchParameterParser::ALLOWED_RETURN_FIELDS,
        debug: {},
      })
    end
  end

  context "filtered, unsorted search" do
    should 'call raw_search with the results from the builder' do
      @combined_index = stub("unified index")
      @searcher = make_searcher
      @combined_index.stubs(:raw_search).with({
        from: 0,
        size: 20,
        query: 'A SUPER LONG QUERY',
        filter: { "terms" => {"organisations" => ["ministry-of-magic"] } },
        fields: SearchParameterParser::ALLOWED_RETURN_FIELDS,
      }).returns(EMPTY_ES_RESPONSE)

      @results = @searcher.search({
        start: 0,
        count: 20,
        query: "cheese",
        filters: [ text_filter("organisations", ["ministry-of-magic"]) ],
        return_fields: SearchParameterParser::ALLOWED_RETURN_FIELDS,
        facets: nil,
        debug: {},
      })
    end
  end

  context "faceted, unsorted search" do
    should 'call raw_search with the results from the builder' do
      @combined_index = stub("unified index")
      @searcher = make_searcher
      @combined_index.stubs(:raw_search).with({
        from: 0,
        size: 20,
        query: 'A SUPER LONG QUERY',
        facets: {
          "organisations" => {
            terms: {
              field: "organisations",
              order: "count",
              size: 100000,
            },
          }
        },
        fields: SearchParameterParser::ALLOWED_RETURN_FIELDS,
      }).returns(EMPTY_ES_RESPONSE.merge(
        "facets" => {"organisations" => {
          "missing" => 7,
          "terms" => [
            {"term" => "a", "count" => 2,},
            {"term" => "b", "count" => 1,},
          ]
        }},
      ))

      @results = @searcher.search({
        start: 0,
        count: 20,
        query: "cheese",
        filters: {},
        return_fields: SearchParameterParser::ALLOWED_RETURN_FIELDS,
        facets: {
          "organisations" => {
            requested: 1,
            examples: 0,
            example_fields: [],
            order: SearchParameterParser::DEFAULT_FACET_SORT,
            scope: :exclude_field_filter
          }
        },
        debug: {},
      })
    end
  end
end
