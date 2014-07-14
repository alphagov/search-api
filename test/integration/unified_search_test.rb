require "integration_test_helper"
require "rest-client"
require_relative "multi_index_test"

class UnifiedSearchTest < MultiIndexTest

  def test_returns_success
    get "/unified_search?q=important"
    assert last_response.ok?
  end

  def test_returns_docs_from_all_indexes
    get "/unified_search?q=important"
    links = parsed_response["results"].map do |result|
      result["link"]
    end
    assert links.include? "/detailed-1"
    assert links.include? "/government-1"
    assert links.include? "/mainstream-1"
  end

  def test_sort_by_date_ascending
    get "/unified_search?q=important&order=public_timestamp"
    links = parsed_response["results"].map do |result|
      result["link"]
    end
    assert_equal ["/government-1", "/government-2"], links
  end

  def test_sort_by_date_descending
    get "/unified_search?q=important&order=-public_timestamp"
    links = parsed_response["results"].map do |result|
      result["link"]
    end
    assert_equal ["/government-2", "/government-1"], links
  end

  def test_filter_by_section
    get "/unified_search?filter_section=1"
    assert last_response.ok?
    links = parsed_response["results"].map do |result|
      result["link"]
    end
    links.sort!
    assert_equal links, ["/detailed-1", "/government-1", "/mainstream-1"], links
  end

  def test_only_contains_fields_which_are_present
    get "/unified_search?q=important&order=public_timestamp"
    results = parsed_response["results"]
    refute_includes results[0].keys, "topics"
    assert_equal ["farming"], results[1]["topics"]
  end

  def test_facet_counting
    get "/unified_search?q=important&facet_section=2"
    assert_equal 6, parsed_response["total"]
    facets = parsed_response["facets"]
    assert_equal({
      "section" => {
        "options" => [
          {"value"=>"2", "documents"=>3},
          {"value"=>"1", "documents"=>3},
        ],
        "documents_with_no_value" => 0,
        "total_options" => 2,
        "missing_options" => 0,
      }
    }, facets)
  end

  def test_facet_counting_missing_options
    get "/unified_search?q=important&facet_section=1"
    assert_equal 6, parsed_response["total"]
    facets = parsed_response["facets"]
    assert_equal({
      "section" => {
        "options" => [
          {"value"=>"2", "documents"=>3},
        ],
        "documents_with_no_value" => 0,
        "total_options" => 2,
        "missing_options" => 1,
      }
    }, facets)
  end

  def test_facet_examples
    get "/unified_search?q=important&facet_section=1,examples:5,example_scope:global,example_fields:link:title:section"
    assert_equal 6, parsed_response["total"]
    facets = parsed_response["facets"]
    assert_equal({
      "value" => {
        "slug" => "2",
        "example_info" => {
          "total" => 3,
          "examples" => [
            {"section" => ["2"], "title" => "Sample mainstream document 2", "link" => "/mainstream-2"},
            {"section" => ["2"], "title" => "Sample detailed document 2", "link" => "/detailed-2"},
            {"section" => ["2"], "title" => "Sample government document 2", "link" => "/government-2"},
          ]
        }
      },
      "documents" => 3,
    }, facets.fetch("section").fetch("options").fetch(0))
  end

  def test_validates_integer_params
    get "/unified_search?start=a"
    assert_equal last_response.status, 422
    assert_equal parsed_response, {"error" => "Invalid value \"a\" for parameter \"start\" (expected positive integer)"}
  end

  def test_allows_integer_params_leading_zeros
    get "/unified_search?start=09"
    assert last_response.ok?
  end

  def test_validates_unknown_params
    get "/unified_search?foo&bar=1"
    assert_equal last_response.status, 422
    assert_equal parsed_response, {"error" => "Unexpected parameters: foo, bar"}
  end

  def test_returns_suggestions_given_query
    get "/unified_search?q=afgananistan"
    assert parsed_response["suggested_queries"].include? "Afghanistan"
  end

  def test_returns_no_suggestions_without_query
    get "/unified_search"
    assert_equal [], parsed_response["suggested_queries"]
  end

  def test_debug_explain_returns_explanations
    get "/unified_search?debug=explain"
    first_hit_explain = parsed_response["results"].first["_explanation"]
    refute_nil first_hit_explain
    assert first_hit_explain.keys.include?("value")
    assert first_hit_explain.keys.include?("description")
    assert first_hit_explain.keys.include?("details")
  end

  def test_can_scope_by_document_type
    insert_document("mainstream_test", cma_case_attributes)
    get "/unified_search?filter_document_type=cma_case"
    assert last_response.ok?
    assert_equal 1, parsed_response.fetch("total")
    assert_equal(
      hash_including(
        "title" => cma_case_attributes.fetch("title"),
        "link" => cma_case_attributes.fetch("link"),
      ),
      parsed_response.fetch("results").fetch(0),
    )
  end

  def cma_case_attributes
    {
      "title" => "Somewhat Unique CMA Case",
      "link" => "/cma-cases/somewhat-unique-cma-case",
      "indexable_content" => "Mergers of cheeses and faces",
      "_type" => "cma_case",
      "tags" => [],
      "topics" => ["farming"],
      "section" => ["1"],
    }
  end
  private :cma_case_attributes
end
