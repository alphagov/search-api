require "test_helper"
require "legacy_search/advanced_search_query_builder"

class AdvancedSearchQueryBuilderTest < MiniTest::Unit::TestCase
  include Fixtures::DefaultMappings

  def build_builder(keywords = "", filter_params = {}, sort_order = {}, mappings = default_mappings)
    LegacySearch::AdvancedSearchQueryBuilder.new(keywords, filter_params, sort_order, mappings)
  end

  def test_builder_excludes_withdrawn
    builder = build_builder
    query_hash = builder.filter_query_hash

    assert_equal(
      query_hash,
      {
        "filter" => {
          "not" => { "term" => { "is_withdrawn" => true } }
        }
      }
    )
  end


  def test_builder_single_filters
    builder = build_builder("how to drive", { "format" => "organisation" })
    query_hash = builder.filter_query_hash

    assert_equal(
      query_hash,
      {
        "filter" => {
          "and" => [
            { "term" => { "format" => "organisation" } },
            { "not" => { "term" => { "is_withdrawn" => true } } }
          ]
        }
      }
    )
  end

  def test_builder_multiple_filters
    builder = build_builder("how to drive", { "format" => "organisation", "specialist_sectors" => "driving" })
    query_hash = builder.filter_query_hash

    assert_equal(
      query_hash,
      {
        "filter" => {
          "and" => [
            { "term" => { "format" => "organisation" } },
            { "term" => { "specialist_sectors" => "driving" } },
            { "not" => { "term" => { "is_withdrawn" => true } } }
          ]
        }
      }
    )
  end
end
