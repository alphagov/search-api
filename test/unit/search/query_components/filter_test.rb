require "test_helper"
require "search/query_builder"

class FilterTest < ShouldaUnitTestCase
  def make_search_params(filters, include_withdrawn: true)
    Search::QueryParameters.new(filters: filters, debug: { include_withdrawn: include_withdrawn })
  end

  def make_date_filter_param(field_name, values)
    SearchParameterParser::DateFieldFilter.new(field_name, values, false)
  end

  def text_filter(field_name, values)
    SearchParameterParser::TextFieldFilter.new(field_name, values, false)
  end

  def reject_filter(field_name, values)
    SearchParameterParser::TextFieldFilter.new(field_name, values, true)
  end

  context "search with one filter" do
    should "append the correct text filters" do
      builder = QueryComponents::Filter.new(
        make_search_params([text_filter("specialist_sectors", ["magic"])])
      )

      result = builder.payload

      assert_equal(
        result,
        { "terms" => { "specialist_sectors" => ["magic"] } }
      )
    end

    should "append the correct date filters" do
      builder = QueryComponents::Filter.new(
        make_search_params([make_date_filter_param("field_with_date", ["from:2014-04-01 00:00,to:2014-04-02 00:00"])])
      )

      result = builder.payload

      assert_equal(
        result,
        { "range" => { "field_with_date" => { "from" => "2014-04-01", "to" => "2014-04-02" } } }
      )
    end
  end

  context "search with a filter with multiple options" do
    should "have correct filter" do
      builder = QueryComponents::Filter.new(
        make_search_params([text_filter("specialist_sectors", ["magic", "air-travel"])])
      )

      result = builder.payload

      assert_equal(
        result,
        { "terms" => { "specialist_sectors" => ["magic", "air-travel"] } }
      )
    end
  end

  context "search with a filter and rejects" do
    should "have correct filter" do
      builder = QueryComponents::Filter.new(
        make_search_params(
          [
            text_filter("specialist_sectors", ["magic", "air-travel"]),
            reject_filter("mainstream_browse_pages", ["benefits"]),
          ]
        )
      )

      result = builder.payload

      assert_equal(
        result,
        { bool: {
          must: { "terms" => { "specialist_sectors" => ["magic", "air-travel"] } },
          must_not: { "terms" => { "mainstream_browse_pages" => ["benefits"] } },
        } }
      )
    end
  end

  context "search with multiple filters" do
    should "have correct filter" do
      builder = QueryComponents::Filter.new(
        make_search_params(
          [
            text_filter("specialist_sectors", ["magic", "air-travel"]),
            text_filter("mainstream_browse_pages", ["levitation"]),
          ],
        )
      )

      result = builder.payload

      assert_equal(
        result,
        {
          and: [
            { "terms" => { "specialist_sectors" => ["magic", "air-travel"] } },
            { "terms" => { "mainstream_browse_pages" => ["levitation"] } },
          ].compact
        }
      )
    end
  end

  context "search with tag filter" do
    should "include the topic itself" do
      builder = QueryComponents::Filter.new(
        make_search_params(
          [
            text_filter("organisations", ["hmrc"]),
          ],
        )
      )

      result = builder.payload

      assert_equal(
        result,
        {
          or: [
            { "terms" => { "organisations" => ["hmrc"] } },

            {
              and: [
                { "terms" => { "slug" => ["hmrc"] } },
                { "term" => { "format" => "organisation" } },
              ]
            }
          ].compact
        }
      )
    end
  end

end
