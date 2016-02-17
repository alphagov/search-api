require "test_helper"
require "unified_search_builder"

class TextQueryTest < ShouldaUnitTestCase
  context "search with debug disabling use of synonyms" do
    should "use the all_searchable_text.synonym field" do
      builder = QueryComponents::TextQuery.new(search_query_params)

      query = builder.payload

      assert_match(/all_searchable_text.synonym/, query.to_s)
    end

    should "not use the all_searchable_text.synonym field" do
      builder = QueryComponents::TextQuery.new(search_query_params(debug: { disable_synonyms: true }))

      query = builder.payload

      refute_match(/all_searchable_text.synonym/, query.to_s)
    end
  end

  context "quoted strings" do
    should "call the payload for quoted strings" do
      params = search_query_params(query: %{"all sorts of stuff"})
      builder = QueryComponents::TextQuery.new(params)
      builder.expects(:payload_for_quoted_phrase).once

      builder.payload
    end
  end

  context "unquoted strings" do
    should "call the payload for unquoted strings" do
      params = search_query_params(query: %{all sorts of stuff})
      builder = QueryComponents::TextQuery.new(params)
      builder.expects(:payload_for_unquoted_phrase).once

      builder.payload
    end
  end
end
