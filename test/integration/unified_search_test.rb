require "integration_test_helper"
require "rest-client"
require_relative "multi_index_test"

class UnifiedSearchTest < MultiIndexTest

  def test_returns_success
    get "/unified_search?q=important"
    assert last_response.ok?
  end

  def test_spell_checking_with_typo
    # The word "important" is imported into the elasticsearch index by the
    # MultiIndexTest setup block.

    get "/unified_search?q=imprtant"

    assert_equal ['important'], parsed_response['suggested_queries']
  end

  def test_spell_checking_without_typo
    get "/unified_search?q=milliband"

    assert_equal [], parsed_response['suggested_queries']
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

    # The government links have dates, so appear before all the other links
    assert_equal ["/government-1", "/government-2"], links.slice(0, 2)

    # The other documents have no dates, so appear in an undefined order
    assert_equal ["/detailed-1", "/detailed-2", "/mainstream-1", "/mainstream-2"], links.slice(2, 6).sort
  end

  def test_sort_by_date_descending
    get "/unified_search?q=important&order=-public_timestamp"
    links = parsed_response["results"].map do |result|
      result["link"]
    end

    # The government links have dates, so appear before all the other links
    assert_equal ["/government-2", "/government-1"], links.slice(0, 2)

    # The other documents have no dates, so appear in an undefined order
    assert_equal ["/detailed-1", "/detailed-2", "/mainstream-1", "/mainstream-2"], links.slice(2, 6).sort
  end

  def test_sort_by_title_ascending
    get "/unified_search?order=title"
    titles = parsed_response["results"].map do |result|
      result["title"]
    end

    lowercase_titles = titles.map(&:downcase)

    assert_equal lowercase_titles, lowercase_titles.sort
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

  def test_reject_by_section
    get "/unified_search?reject_section=1"
    assert last_response.ok?
    links = parsed_response["results"].map do |result|
      result["link"]
    end
    links.sort!
    assert_equal links, ["/detailed-2", "/government-2", "/mainstream-2"], links
  end

  def test_can_filter_for_missing_section_field
    get "/unified_search?filter_specialist_sectors=_MISSING"
    assert last_response.ok?
    links = parsed_response["results"].map do |result|
      result["link"]
    end
    links.sort!
    assert_equal ["/detailed-1", "/government-1", "/mainstream-1"], links
  end

  def test_can_filter_for_missing_or_specific_value_section_field
    get "/unified_search?filter_specialist_sectors[]=_MISSING&filter_specialist_sectors[]=farming"
    assert last_response.ok?
    links = parsed_response["results"].map do |result|
      result["link"]
    end
    links.sort!
    assert_equal [
      "/detailed-1", "/detailed-2",
      "/government-1", "/government-2",
      "/mainstream-1", "/mainstream-2",
    ], links
  end

  def test_can_filter_and_reject
    get "/unified_search?reject_section=1&filter_specialist_sectors[]=farming"
    assert last_response.ok?
    links = parsed_response["results"].map do |result|
      result["link"]
    end
    links.sort!
    assert_equal [
      "/detailed-2",
      "/government-2",
      "/mainstream-2",
    ], links
  end

  def test_only_contains_fields_which_are_present
    get "/unified_search?q=important&order=public_timestamp"
    results = parsed_response["results"]
    refute_includes results[0].keys, "specialist_sectors"
    assert_equal [{"slug"=>"farming"}], results[1]["specialist_sectors"]
  end

  def test_facet_counting
    get "/unified_search?q=important&facet_section=2"
    assert_equal 6, parsed_response["total"]
    facets = parsed_response["facets"]
    assert_equal({
      "section" => {
        "options" => [
          {"value"=>{"slug"=>"1"}, "documents"=>3},
          {"value"=>{"slug"=>"2"}, "documents"=>3},
        ],
        "documents_with_no_value" => 0,
        "total_options" => 2,
        "missing_options" => 0,
        "scope" => "exclude_field_filter",
      }
    }, facets)
  end

  def test_facet_counting_with_filter_on_field_and_exclude_field_filter_scope
    get "/unified_search?q=important&facet_section=2"
    assert_equal 6, parsed_response["total"]
    facets_without_filter = parsed_response["facets"]

    get "/unified_search?q=important&facet_section=2&filter_section=1"
    assert_equal 3, parsed_response["total"]
    facets_with_filter = parsed_response["facets"]

    assert_equal(facets_with_filter, facets_without_filter)
  end

  def test_facet_counting_missing_options
    get "/unified_search?q=important&facet_section=1"
    assert_equal 6, parsed_response["total"]
    facets = parsed_response["facets"]
    assert_equal({
      "section" => {
        "options" => [
          {"value"=>{"slug"=>"1"}, "documents"=>3},
        ],
        "documents_with_no_value" => 0,
        "total_options" => 2,
        "missing_options" => 1,
        "scope" => "exclude_field_filter",
      }
    }, facets)
  end

  def test_facet_counting_with_filter_on_field_and_all_filters_scope
    get "/unified_search?q=important&facet_section=2,scope:all_filters&filter_section=1"
    assert_equal 3, parsed_response["total"]
    facets = parsed_response["facets"]

    assert_equal({
      "section" => {
        "options" => [
          {"value"=>{"slug"=>"1"}, "documents"=>3},
        ],
        "documents_with_no_value" => 0,
        "total_options" => 1,
        "missing_options" => 0,
        "scope" => "all_filters",
      }
    }, facets)
  end

  def test_facet_examples
    get "/unified_search?q=important&facet_section=1,examples:5,example_scope:global,example_fields:link:title:section"
    assert_equal 6, parsed_response["total"]
    facets = parsed_response["facets"]
    assert_equal({
      "value" => {
        "slug" => "1",
        "example_info" => {
          "total" => 3,
          "examples" => [
            {"section" => "1", "title" => "sample mainstream document 1", "link" => "/mainstream-1"},
            {"section" => "1", "title" => "sample detailed document 1", "link" => "/detailed-1"},
            {"section" => "1", "title" => "sample government document 1", "link" => "/government-1"},
          ]
        }
      },
      "documents" => 3,
    }, facets.fetch("section").fetch("options").fetch(0))
  end

  def test_facet_examples_with_example_scope_query
    get "/unified_search?q=important&facet_section=1,examples:5,example_scope:query,example_fields:link:title:section"

    assert_equal 6, parsed_response["total"]

    facets = parsed_response["facets"]
    assert_equal({
      "value" => {
        "slug" => "1",
        "example_info" => {
          "total" => 3,
          "examples" => [
            {"section" => "1", "title" => "sample mainstream document 1", "link" => "/mainstream-1"},
            {"section" => "1", "title" => "sample detailed document 1", "link" => "/detailed-1"},
            {"section" => "1", "title" => "sample government document 1", "link" => "/government-1"},
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
        "document_type" => cma_case_attributes.fetch("_type"),
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
      "specialist_sectors" => ["farming"],
      "section" => ["1"],
      "opened_date" => "2014-04-01",
    }
  end
  private :cma_case_attributes

  def test_can_filter_between_dates
    insert_document("mainstream_test", cma_case_attributes)

    get "/unified_search?filter_document_type=cma_case&filter_opened_date=from:2014-03-31,to:2014-04-02"
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

  def test_can_filter_between_dates_with_reversed_parameter_order
    insert_document("mainstream_test", cma_case_attributes)

    get "/unified_search?filter_document_type=cma_case&filter_opened_date=to:2014-04-02,from:2014-03-31"
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

  def test_can_filter_from_date
    insert_document("mainstream_test", cma_case_attributes)

    get "/unified_search?filter_document_type=cma_case&filter_opened_date=from:2014-03-31"
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

  def test_can_filter_to_date
    insert_document("mainstream_test", cma_case_attributes)

    get "/unified_search?filter_document_type=cma_case&filter_opened_date=to:2014-04-02"
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

  def test_cannot_provide_date_filter_key_multiple_times
    get "/unified_search?filter_document_type=cma_case&filter_opened_date[]=from:2014-03-31&filter_opened_date[]=to:2014-04-02"
    assert_equal 422, last_response.status
    assert_equal(
      {"error" => %{Too many values (2) for parameter "opened_date" (must occur at most once)}},
      parsed_response,
    )
  end

  def test_cannot_provide_invalid_dates_for_date_filter
    get "/unified_search?filter_document_type=cma_case&filter_opened_date=from:not-a-date"
    assert_equal 422, last_response.status
    assert_equal(
      {"error" => %{Invalid value "not-a-date" for parameter "opened_date" (expected ISO8601 date}},
      parsed_response,
    )
  end
end
