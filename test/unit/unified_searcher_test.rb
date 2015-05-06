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

  BASE_CHEESE_QUERY = {
    function_score: {
      boost_mode: :multiply,
      query: {
        function_score: {
          boost_mode: :multiply,
          query: {bool: {
            should: [
              {bool: {
                must: [
                  {match: {_all: {
                    query: 'cheese',
                    analyzer: 'query_default',
                    minimum_should_match: '2<2 3<3 7<50%'
                  }}},
                ],
                should: [
                  {match_phrase: {'title' => {query: 'cheese', analyzer: 'query_default'}}},
                  {match_phrase: {'acronym' => {query: 'cheese', analyzer: 'query_default'}}},
                  {match_phrase: {'description' => {query: 'cheese', analyzer: 'query_default'}}},
                  {match_phrase: {'indexable_content' => {query: 'cheese', analyzer: 'query_default'}}},
                  {multi_match: {
                    query: 'cheese',
                    operator: 'and',
                    fields: ['title', 'acronym', 'description', 'indexable_content'],
                    analyzer: 'query_default',
                  }},
                  {multi_match: {
                    query: 'cheese',
                    operator: 'or',
                    fields: ['title', 'acronym', 'description', 'indexable_content'],
                    analyzer: 'shingled_query_analyzer',
                  }},
                ]}
              },
            ]
          }},
          functions: [
            {filter: {term: {format: 'smart-answer'}}, boost_factor: 1.5},
            {filter: {term: {format: 'transaction'}}, boost_factor: 1.5},
            {filter: {term: {format: 'topical_event'}}, boost_factor: 1.5},
            {filter: {term: {format: 'minister'}}, boost_factor: 1.7},
            {filter: {term: {format: 'organisation'}}, boost_factor: 2.5},
            {filter: {term: {format: 'topic'}}, boost_factor: 1.5},
            {filter: {term: {format: 'document_series'}}, boost_factor: 1.3},
            {filter: {term: {format: 'document_collection'}}, boost_factor: 1.3},
            {filter: {term: {format: 'operational_field'}}, boost_factor: 1.5},
            {filter: {term: {format: 'contact'}}, boost_factor: 0.3},
            {filter: {term: {search_format_types: 'announcement'}}, script_score: {
              script: "((0.05 / ((3.16*pow(10,-11)) * abs(now - doc['public_timestamp'].date.getMillis()) + 0.05)) + 0.12)",
              params: {now: (Time.now.to_i / 60) * 60000},
            }},
            {filter: {term: {organisation_state: 'closed'}}, boost_factor: 0.3},
            {filter: {term: {organisation_state: 'devolved'}}, boost_factor: 0.3},
            {filter: {term: {is_historic: true}}, boost_factor: 0.5},
          ],
          score_mode: 'multiply',
        }
      },
      script_score: {
        script: "doc['popularity'].value + #{UnifiedSearchBuilder::POPULARITY_OFFSET}"
      },
    }
  }

  CHEESE_QUERY = {
    indices: {
      index: :government,
      query: {
        function_score: {
          query: BASE_CHEESE_QUERY,
          boost_factor: 0.4
        }
      },
      no_match_query: {
        indices: {
          index: :"service-manual",
          query: {
            function_score: {
              query: BASE_CHEESE_QUERY,
              boost_factor: 0.1
            }
          },
          no_match_query: BASE_CHEESE_QUERY
        }
      }
    }
  }

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
        query: CHEESE_QUERY,
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
        query: CHEESE_QUERY,
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
        query: CHEESE_QUERY,
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
    setup do
      @combined_index = stub("unified index")
      @searcher = make_searcher
      @combined_index.stubs(:raw_search).with({
        from: 0,
        size: 20,
        query: CHEESE_QUERY,
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

    should "include requested number of facet options" do
      facet = @results[:facets]["organisations"]
      assert_equal(1, facet[:options].length)
    end

    should "have correct top facet option" do
      facet = @results[:facets]["organisations"]
      assert_equal({value: {"slug" => "a"}, documents: 2}, facet[:options][0])
    end

    should "include requested number of facets" do
      facet = @results[:facets]["organisations"]
      assert_equal(2, facet[:total_options])
      assert_equal(1, facet[:missing_options])
    end

    should "include number of documents with no value" do
      facet = @results[:facets]["organisations"]
      assert_equal(7, facet[:documents_with_no_value])
    end

    should "include requested facet scope" do
      facet = @results[:facets]["organisations"]
      assert_equal(:exclude_field_filter, facet[:scope])
    end
  end
end
