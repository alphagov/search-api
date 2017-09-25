require 'spec_helper'

RSpec.describe 'AggregateExampleFetcherTest', tags: ['shoulda'] do
  def query_for_example_global(field, value, return_fields)
    {
      query: {
        filtered: {
          query: nil,
          filter: {
            and: [
              { term: { field => value } },
              { indices: {
                indices: SearchConfig.instance.elasticsearch['content_index_names'],
                filter: {},
                no_match_filter: 'none'
              } }
            ]
          },
        },
      },
      size: 2,
      fields: return_fields,
      sort: [{ popularity: { order: :desc } }]
    }
  end

  def query_for_example_query(field, value, return_fields, query, filter)
    {
      query: { filtered: { query: query, filter: { and: [
        { term: { field => value } },
        filter
      ] } } },
      size: 2,
      fields: return_fields,
      sort: [{ popularity: { order: :desc } }]
    }
  end

  def response_for_example(total_examples, titles)
    {
      "hits" => {
        "total" => total_examples,
        "hits" => titles.map { |title|
          { "fields" => { "title" => title } }
        }
      }
    }
  end

  def stub_index(_name)
    schema = stub("schema")
    schema.stubs(:field_definitions).returns(sample_field_definitions)
    index = stub("content index")
    index.stubs(:schema).returns(schema)
    index
  end

  context "#prepare_response" do
    it "map an empty response" do
      fetcher = Search::AggregateExampleFetcher.new(@index, {}, Search::QueryParameters.new, @builder)

      response = fetcher.send(:prepare_response, [], [])

      assert_equal response, {}
    end

    it "map a response to aggregates without fields" do
      fetcher = Search::AggregateExampleFetcher.new(@index, {}, Search::QueryParameters.new, @builder)
      slugs = ['a-slug-name']
      response_list = [{ 'hits' => { 'total' => 1, 'hits' => [{ '_id' => 'a-slug-name' }] } }]

      response = fetcher.send(:prepare_response, slugs, response_list)

      assert_equal response, { "a-slug-name" => { total: 1, examples: [{}] } }
    end
  end

  context "no aggregate" do
    before do
      @index = stub_index("content index")
      @builder = stub("builder")
      @fetcher = Search::AggregateExampleFetcher.new(@index, {}, Search::QueryParameters.new, @builder)
    end

    it "get an empty hash of examples" do
      assert_equal({}, @fetcher.fetch)
    end
  end

  context "one aggregate with global scope" do
    before do
      GovukIndex::MigratedFormats.stubs(:migrated_formats).returns([])
      @index = stub_index("content index")
      @example_fields = %w{link title other_field}
      main_query_response = { "aggregations" => {
        "sector" => {
          'filtered_aggregations' => {
            "buckets" => [
              { "key" => "sector_1" },
              { "key" => "sector_2" },
            ]
          }
        }
      } }
      params = Search::QueryParameters.new(
        aggregates: {
          "sector" => {
            requested: 10,
            examples: 2,
            example_fields: @example_fields,
            example_scope: :global
          }
        }
      )
      @builder = stub("builder")
      @fetcher = Search::AggregateExampleFetcher.new(@index, main_query_response, params, @builder)
    end

    it "request and return aggregate examples" do
      @index.expects(:msearch)
        .with([
          query_for_example_global("sector", "sector_1", @example_fields),
          query_for_example_global("sector", "sector_2", @example_fields),
        ]).returns({ "responses" => [
          response_for_example(3, %w(example_1 example_2)),
          response_for_example(1, ["example_3"]),
        ] })

      assert_equal({
        "sector" => {
          "sector_1" => { total: 3, examples: [
              { "title" => "example_1" },
              { "title" => "example_2" }
            ] },
          "sector_2" => { total: 1, examples: [
              { "title" => "example_3" }
            ] },
        }
      }, @fetcher.fetch)
    end
  end

  context "one aggregate with query scope" do
    before do
      @index = stub_index("content index")
      @example_fields = %w{link title other_field}

      main_query_response = { "aggregations" => {
        "sector" => {
          'filtered_aggregations' => {
            "buckets" => [
              { "key" => "sector_1" },
              { "key" => "sector_2" },
            ]
          }
        }
      } }

      params = Search::QueryParameters.new(
        aggregates: {
          "sector" => {
            requested: 10,
            examples: 2,
            example_fields: @example_fields,
            example_scope: :query
          }
        }
      )

      @builder = stub("builder")
      @fetcher = Search::AggregateExampleFetcher.new(@index, main_query_response, params, @builder)
    end

    it "request and return aggregate examples with query scope" do
      query = { match: { _all: { query: "hello" } } }
      filter = { terms: { organisations: ["hm-magic"] } }
      @builder.expects(:query).returns(query)
      @builder.expects(:filter).returns(filter)

      @index.expects(:msearch)
        .with([
          query_for_example_query("sector", "sector_1", @example_fields, query, filter),
          query_for_example_query("sector", "sector_2", @example_fields, query, filter),
        ]).returns({ "responses" => [
          response_for_example(3, %w(example_1 example_2)),
          response_for_example(1, ["example_3"]),
        ] })

      assert_equal({
        "sector" => {
          "sector_1" => { total: 3, examples: [
              { "title" => "example_1" },
              { "title" => "example_2" }
            ] },
          "sector_2" => { total: 1, examples: [
              { "title" => "example_3" }
            ] },
        }
      }, @fetcher.fetch)
    end
  end

  context "one aggregate but no documents match query" do
    before do
      @index = stub_index("content index")
      @example_fields = %w{link title other_field}
      main_query_response = { "aggregations" => {
        "sector" => {
          'filtered_aggregations' => {
            "buckets" => [
            ]
          }
        }
      } }
      params = Search::QueryParameters.new(
        aggregates: {
          "sector" => {
            requested: 10,
            examples: 2,
            example_fields: @example_fields,
            example_scope: :global
          }
        }
      )
      @builder = stub("builder")
      @fetcher = Search::AggregateExampleFetcher.new(@index, main_query_response, params, @builder)
    end

    it "request and return aggregate examples" do
      assert_equal({ "sector" => {} }, @fetcher.fetch)
    end
  end

  context "one aggregate with 1000 matches" do
    before do
      @index = stub_index("content index")
      @example_fields = %w{link title other_field}

      main_query_response = { "aggregations" => {
        "sector" => {
          'filtered_aggregations' => {
            "buckets" => Array((0..999).map { |i|
              { "key" => "sector_#{i}" }
            })
          }
        }
      } }

      params = Search::QueryParameters.new(
        aggregates: {
          "sector" => {
            requested: 10,
            examples: 2,
            example_fields: @example_fields,
            example_scope: :query
          }
        }
      )

      @builder = stub("builder")
      @fetcher = Search::AggregateExampleFetcher.new(@index, main_query_response, params, @builder)
    end

    it "request and return aggregate examples with query scope" do
      query = { match: { _all: { query: "hello" } } }
      filter = { terms: { organisations: ["hm-magic"] } }
      @builder.expects(:query).returns(query)
      @builder.expects(:filter).returns(filter)

      (0..19).each do |group_num|
        sector_numbers = (group_num * 50..group_num * 50 + 49)
        expected_queries = Array(
          sector_numbers.map { |sector_num|
            query_for_example_query("sector", "sector_#{sector_num}", @example_fields, query, filter)
          })
        stub_responses = Array(
          sector_numbers.map { |sector_num|
            response_for_example(sector_num, ["example_#{sector_num}"])
          })
        @index.expects(:msearch)
          .with(expected_queries).returns({ "responses" => stub_responses })
      end

      assert_equal({
        "sector" => Hash[
          (0..999).map { |sector_num|
            [
              "sector_#{sector_num}",
              { total: sector_num, examples: [{ "title" => "example_#{sector_num}" }] }
            ]
          }
        ]
      }, @fetcher.fetch)
    end
  end
end
