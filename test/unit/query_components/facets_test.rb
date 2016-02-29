require "test_helper"
require "search/search_builder"

class FacetsTest < ShouldaUnitTestCase
  def make_search_params(facets:, filters: [])
    Search::SearchParameters.new(
      filters: filters, facets: facets, debug: { include_withdrawn: true }
    )
  end

  context "search with facet" do
    should "have correct facet in payload" do
      builder = QueryComponents::Facets.new(
        make_search_params(
          facets: { "organisations" => { requested: 10, scope: :exclude_field_filter } },
        )
      )

      result = builder.payload

      assert_equal(
        {
          "organisations" => {
            terms: {
              field: "organisations",
              order: "count",
              size: 100000,
            },
          },
        },
        result
      )
    end
  end

  context "search with facet and filter on same field" do
    setup do
      @builder = QueryComponents::Facets.new(
        make_search_params(
          filters: [text_filter("organisations", ["hm-magic"])],
          facets: { "organisations" => { requested: 10, scope: :exclude_field_filter } },
        )
      )
    end

    should "have correct facet in payload" do
      assert_equal(
        {
          "organisations" => {
            terms: {
              field: "organisations",
              order: "count",
              size: 100000,
            },
          },
        },
        @builder.payload)
    end
  end

  context "search with facet and filter on same field, and scope set to all_filters" do
    setup do
      @builder = QueryComponents::Facets.new(
        make_search_params(
          filters: [text_filter("organisations", ["hm-magic"])],
          facets: { "organisations" => { requested: 10, scope: :all_filters } },
        )
      )
    end

    should "have correct facet in payload" do
      assert_equal(
        {
          "organisations" => {
            terms: {
              field: "organisations",
              order: "count",
              size: 100000,
            },
            facet_filter: {
              "terms" => { "organisations" => ["hm-magic"] }
            },
          },
        },
        @builder.payload)
    end
  end

  context "search with facet and filter on different field" do
    setup do
      @builder = QueryComponents::Facets.new(
        make_search_params(
          filters: [text_filter("mainstream_browse_pages", "levitation")],
          facets: { "organisations" => { requested: 10, scope: :exclude_field_filter } },
        )
      )
    end

    should "have facet with facet_filter in payload" do
      assert_equal(
        {
          "organisations" => {
            terms: {
              field: "organisations",
              order: "count",
              size: 100000,
            },
            facet_filter: {
              "terms" => { "mainstream_browse_pages" => ["levitation"] }
            },
          },
        },
        @builder.payload)
    end
  end

  def text_filter(field_name, values, reject = false)
    SearchParameterParser::TextFieldFilter.new(field_name, values, reject)
  end
end
