require "test_helper"
require "facet_example_fetcher"

class FacetExampleFetcherTest < ShouldaUnitTestCase

  def query_for_example(field, value, return_fields)
    {
      query: {filtered: {filter: {term: {field => value}}}},
      size: 2,
      fields: return_fields,
      sort: [{popularity: {order: :desc}}]
    }
  end

  def response_for_example(total_examples, titles)
    {
      "hits" => {
        "total" => total_examples,
        "hits" => titles.map { |title|
          {"fields" => {"title" => title}}
        }
      }
    }
  end

  context "no facet" do
    setup do
      @index = stub("content index")
      @fetcher = FacetExampleFetcher.new(@index, {}, {})
    end

    should "get an empty hash of examples" do
      assert_equal({}, @fetcher.fetch)
    end
  end

  context "one facet" do
    setup do
      @index = stub("content index")
      @example_fields = %w{link title other_field}
      main_query_response = {"facets" => {
        "sector" => {
          "terms" => [
            {"term" => "sector_1"},
            {"term" => "sector_2"},
          ]
        }
      }}
      params = {
        facets: {
          "sector" => {
            requested: 10,
            examples: 2,
            example_fields: @example_fields,
            example_scope: :global
          }
        }
      }
      @fetcher = FacetExampleFetcher.new(@index, main_query_response, params)
    end

    should "request and return facet examples" do
      @index.expects(:msearch)
        .with([
          query_for_example("sector", "sector_1", @example_fields),
          query_for_example("sector", "sector_2", @example_fields),
        ]).returns({"responses" => [
          response_for_example(3, ["example_1", "example_2"]),
          response_for_example(1, ["example_3"]),
        ]})

      assert_equal({
        "sector" => {
          "sector_1" => {total: 3, examples: [
              {"title" => "example_1"},
              {"title" => "example_2"}
            ]},
          "sector_2" => {total: 1, examples: [
              {"title" => "example_3"}
            ]},
        }
      }, @fetcher.fetch)
    end
  end
end
