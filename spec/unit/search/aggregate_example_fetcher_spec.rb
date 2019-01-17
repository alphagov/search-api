require 'spec_helper'

RSpec.describe Search::AggregateExampleFetcher do
  def query_for_example_global(field, value, return_fields)
    {
      bool: {
        must: {
          query: nil,
          filter: {
            bool: {
              must: [
                { term: { field => value } },
                { indices: {
                  indices: SearchConfig.instance.content_index_names,
                  filter: {},
                  no_match_filter: 'none'
                } }
              ]
            },
          },
        },
      },
      size: 2,
      _source: {
        includes: return_fields
      },
      sort: [{ popularity: { order: :desc } }]
    }
  end

  def query_for_example_query(field, value, return_fields, query, filter)
    {
      query: {
        bool: {
          must: {
            query: query,
            filter: {
              bool: {
                must: [
                  { term: { field => value } },
                  filter
                ]
              }
            }
          }
        }
      },
      size: 2,
      _source: {
        includes: return_fields
      },
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
    schema = double("schema")
    allow(schema).to receive(:field_definitions).and_return(sample_field_definitions)
    index = double("content index")
    allow(index).to receive(:schema).and_return(schema)
    index
  end

  context "#prepare_response" do
    it "map an empty response" do
      fetcher = described_class.new(@index, {}, Search::QueryParameters.new, @builder)

      response = fetcher.send(:prepare_response, [], [])

      expect(response).to eq({})
    end

    it "map a response to aggregates without fields" do
      fetcher = described_class.new(@index, {}, Search::QueryParameters.new, @builder)
      slugs = ['a-slug-name']
      response_list = [{ 'hits' => { 'total' => 1, 'hits' => [{ '_id' => 'a-slug-name' }] } }]

      response = fetcher.send(:prepare_response, slugs, response_list)

      expect(response).to eq("a-slug-name" => { total: 1, examples: [{}] })
    end
  end

  context "no aggregate" do
    before do
      @index = stub_index("content index")
      @builder = double("builder")
      @fetcher = described_class.new(@index, {}, Search::QueryParameters.new, @builder)
    end

    it "get an empty hash of examples" do
      expect(@fetcher.fetch).to eq({})
    end
  end

  context "one aggregate with global scope" do
    before do
      allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return({})
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
      @builder = double("builder")
      @fetcher = described_class.new(@index, main_query_response, params, @builder)
    end

    it "request and return aggregate examples" do
      expect(@index).to receive(:msearch)
        .with([
          query_for_example_global("sector", "sector_1", @example_fields),
          query_for_example_global("sector", "sector_2", @example_fields),
        ]).and_return({ "responses" => [
          response_for_example(3, %w(example_1 example_2)),
          response_for_example(1, ["example_3"]),
        ] })

      expect(
        "sector" => {
          "sector_1" => { total: 3, examples: [
              { "title" => "example_1" },
              { "title" => "example_2" }
            ] },
          "sector_2" => { total: 1, examples: [
              { "title" => "example_3" }
            ] },
        }
      ).to eq(@fetcher.fetch)
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

      @builder = double("builder")
      @fetcher = described_class.new(@index, main_query_response, params, @builder)
    end

    it "request and return aggregate examples with query scope" do
      query = { match: { _all: { query: "hello" } } }
      filter = { terms: { organisations: ["hm-magic"] } }
      expect(@builder).to receive(:query).and_return(query)
      expect(@builder).to receive(:filter).and_return(filter)

      expect(@index).to receive(:msearch)
        .with([
          query_for_example_query("sector", "sector_1", @example_fields, query, filter),
          query_for_example_query("sector", "sector_2", @example_fields, query, filter),
        ]).and_return({ "responses" => [
          response_for_example(3, %w(example_1 example_2)),
          response_for_example(1, ["example_3"]),
        ] })

      expect(
        "sector" => {
          "sector_1" => { total: 3, examples: [
              { "title" => "example_1" },
              { "title" => "example_2" }
            ] },
          "sector_2" => { total: 1, examples: [
              { "title" => "example_3" }
            ] },
        }
      ).to eq(@fetcher.fetch)
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
      @builder = double("builder")
      @fetcher = described_class.new(@index, main_query_response, params, @builder)
    end

    it "request and return aggregate examples" do
      expect(@fetcher.fetch).to eq({ "sector" => {} })
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

      @builder = double("builder")
      @fetcher = described_class.new(@index, main_query_response, params, @builder)
    end

    it "request and return aggregate examples with query scope" do
      query = { match: { _all: { query: "hello" } } }
      filter = { terms: { organisations: ["hm-magic"] } }
      expect(@builder).to receive(:query).and_return(query)
      expect(@builder).to receive(:filter).and_return(filter)

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
        expect(@index).to receive(:msearch)
          .with(expected_queries).and_return({ "responses" => stub_responses })
      end

      expect(
        "sector" => Hash[
          (0..999).map { |sector_num|
            [
              "sector_#{sector_num}",
              { total: sector_num, examples: [{ "title" => "example_#{sector_num}" }] }
            ]
          }
        ]
      ).to eq(@fetcher.fetch)
    end
  end
end
