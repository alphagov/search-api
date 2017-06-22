require "integration_test_helper"

class SearchTest < IntegrationTest
  def setup
    # `@@registries` are set in Rummager and is *not* reset between tests. To
    # prevent caching issues we manually clear them here to make a "new" app.
    Rummager.class_variable_set(:'@@registries', nil)
    super
  end

  def test_returns_success
    get "/search?q=important"

    assert last_response.ok?
  end

  def test_id_code_with_space
    # when debug mode includes "use_id_codes" and it searches for
    # "P 60" instead of "P60" a P60 document should be found!

    commit_document(
      "mainstream_test",
      title: "Get P45, P60 and other forms for your employees",
      description: "Get PAYE forms from HMRC including P45, P60, starter checklist (which replaced the P46), P11D(b)",
      link: "/get-paye-forms-p45-p60"

    )

    get "/search?q=p+60&debug=use_id_codes"

    assert_equal(parsed_response['results'].size, 1)
    assert_equal(parsed_response["results"][0]["link"], "/get-paye-forms-p45-p60")

    get "/search?q=p+60"
    assert_equal(parsed_response['results'].size, 0)
  end

  def test_spell_checking_with_typo
    commit_document("mainstream_test",
      title: "I am the result",
      description: "This is a test search result",
      link: "/some-nice-link"
    )

    get "/search?q=serch&suggest=spelling"

    assert_equal ['search'], parsed_response['suggested_queries']
  end

  def test_spell_checking_without_typo
    populate_content_indexes(section_count: 1)

    get "/search?q=milliband"

    assert_equal [], parsed_response['suggested_queries']
  end

  def test_returns_docs_from_all_indexes
    populate_content_indexes(section_count: 1)

    get "/search?q=important"

    assert result_links.include? "/government-1"
    assert result_links.include? "/mainstream-1"
  end

  def test_sort_by_date_ascending
    populate_content_indexes(section_count: 2)

    get "/search?q=important&order=public_timestamp"

    assert_equal ["/government-1", "/government-2"],
      result_links.take(2)
  end

  def test_sort_by_date_descending
    populate_content_indexes(section_count: 2)

    get "/search?q=important&order=-public_timestamp"

    # The government links have dates, so appear before all the other links.
    # The other documents have no dates, so appear in an undefined order
    assert_equal ["/government-2", "/government-1"],
      result_links.take(2)
  end

  def test_sort_by_title_ascending
    populate_content_indexes(section_count: 1)

    get "/search?order=title"
    lowercase_titles = result_titles.map(&:downcase)

    assert_equal lowercase_titles, lowercase_titles.sort
  end

  def test_filter_by_field
    populate_content_indexes(section_count: 1)

    get "/search?filter_mainstream_browse_pages=browse/page/1"

    assert_equal ["/government-1", "/mainstream-1"],
      result_links.sort
  end

  def test_reject_by_field
    populate_content_indexes(section_count: 2)

    get "/search?reject_mainstream_browse_pages=browse/page/1"

    assert_equal ["/government-2", "/mainstream-2"],
      result_links.sort
  end

  def test_can_filter_for_missing_field
    populate_content_indexes(section_count: 1)

    get "/search?filter_specialist_sectors=_MISSING"

    assert_equal ["/government-1", "/mainstream-1"],
      result_links.sort
  end

  def test_can_filter_for_missing_or_specific_value_in_field
    populate_content_indexes(section_count: 1)

    get "/search?filter_specialist_sectors[]=_MISSING&filter_specialist_sectors[]=farming"

    assert_equal ["/government-1", "/mainstream-1"],
      result_links.sort
  end

  def test_can_filter_and_reject
    populate_content_indexes(section_count: 2)

    get "/search?reject_mainstream_browse_pages=1&filter_specialist_sectors[]=farming"

    assert_equal [
      "/government-2",
      "/mainstream-2",
    ], result_links.sort
  end

  def test_only_contains_fields_which_are_present
    populate_content_indexes(section_count: 2)

    get "/search?q=important&order=public_timestamp"

    results = parsed_response["results"]
    refute_includes results[0].keys, "specialist_sectors"
    assert_equal [{ "slug" => "farming" }], results[1]["specialist_sectors"]
  end

  def test_aggregate_counting
    populate_content_indexes(section_count: 2)

    get "/search?q=important&aggregate_mainstream_browse_pages=2"

    assert_equal 4, parsed_response["total"]

    aggregate = parsed_response["aggregates"]

    assert_equal({
      "mainstream_browse_pages" => {
        "options" => [
          { "value" => { "slug" => "browse/page/1" }, "documents" => 2 },
          { "value" => { "slug" => "browse/page/2" }, "documents" => 2 },
        ],
        "documents_with_no_value" => 0,
        "total_options" => 2,
        "missing_options" => 0,
        "scope" => "exclude_field_filter",
      }
    }, aggregate)
  end

  # we changed facet -> aggregate but still support both
  # the result set should match the naming used in the request
  def test_aggregate_counting_using_facets
    populate_content_indexes(section_count: 2)

    get "/search?q=important&facet_mainstream_browse_pages=2"

    assert_equal 4, parsed_response["total"]

    facets = parsed_response["facets"]

    assert_equal({
      "mainstream_browse_pages" => {
        "options" => [
          { "value" => { "slug" => "browse/page/1" }, "documents" => 2 },
          { "value" => { "slug" => "browse/page/2" }, "documents" => 2 },
        ],
        "documents_with_no_value" => 0,
        "total_options" => 2,
        "missing_options" => 0,
        "scope" => "exclude_field_filter",
      }
    }, facets)
    assert_nil(parsed_response['aggregates'])
  end

  # TODO: The `mainstream_browse_pages` fields are populated with a number, 1
  # or 2. This should be made more explicit.
  def test_aggregate_counting_with_filter_on_field_and_exclude_field_filter_scope
    populate_content_indexes(section_count: 2)

    get "/search?q=important&aggregate_mainstream_browse_pages=2"

    assert_equal 4, parsed_response["total"]
    aggregates_without_filter = parsed_response["aggregates"]

    get "/search?q=important&aggregate_mainstream_browse_pages=2&filter_mainstream_browse_pages=browse/page/1"
    assert_equal 2, parsed_response["total"]

    aggregates_with_filter = parsed_response["aggregates"]

    assert_equal(aggregates_with_filter, aggregates_without_filter)
    assert_equal(2, aggregates_without_filter["mainstream_browse_pages"]["options"].size)
  end

  def test_aggregate_counting_missing_options
    populate_content_indexes(section_count: 2)

    get "/search?q=important&aggregate_mainstream_browse_pages=1"

    assert_equal 4, parsed_response["total"]
    aggregates = parsed_response["aggregates"]
    assert_equal({
      "mainstream_browse_pages" => {
        "options" => [
          { "value" => { "slug" => "browse/page/1" }, "documents" => 2 },
        ],
        "documents_with_no_value" => 0,
        "total_options" => 2,
        "missing_options" => 1,
        "scope" => "exclude_field_filter",
      }
    }, aggregates)
  end

  def test_aggregate_counting_with_filter_on_field_and_all_filters_scope
    populate_content_indexes(section_count: 2)

    get "/search?q=important&aggregate_mainstream_browse_pages=2,scope:all_filters&filter_mainstream_browse_pages=browse/page/1"

    assert_equal 2, parsed_response["total"]
    aggregates = parsed_response["aggregates"]

    assert_equal({
      "mainstream_browse_pages" => {
        "options" => [
          { "value" => { "slug" => "browse/page/1" }, "documents" => 2 },
        ],
        "documents_with_no_value" => 0,
        "total_options" => 1,
        "missing_options" => 0,
        "scope" => "all_filters",
      }
    }, aggregates)
  end

  def test_aggregate_examples
    populate_content_indexes(section_count: 2)

    get "/search?q=important&aggregate_mainstream_browse_pages=1,examples:5,example_scope:global,example_fields:link:title:mainstream_browse_pages"

    assert_equal(
      ["/government-1", "/mainstream-1"],
      parsed_response["aggregates"]["mainstream_browse_pages"]["options"].first["value"]["example_info"]["examples"].map { |h| h["link"] }.sort
    )
  end

  def test_validates_integer_params
    get "/search?start=a"

    assert_equal last_response.status, 422
    assert_equal parsed_response, { "error" => "Invalid value \"a\" for parameter \"start\" (expected positive integer)" }
  end

  def test_allows_integer_params_leading_zeros
    get "/search?start=09"

    assert last_response.ok?
  end

  def test_validates_unknown_params
    get "/search?foo&bar=1"

    assert_equal last_response.status, 422
    assert_equal parsed_response, { "error" => "Unexpected parameters: foo, bar" }
  end

  def test_debug_explain_returns_explanations
    populate_content_indexes(section_count: 1)

    get "/search?debug=explain"

    first_hit_explain = parsed_response["results"].first["_explanation"]
    refute_nil first_hit_explain
    assert first_hit_explain.keys.include?("value")
    assert first_hit_explain.keys.include?("description")
    assert first_hit_explain.keys.include?("details")
  end

  def test_can_scope_by_elasticsearch_type
    commit_document("mainstream_test", cma_case_attributes)

    get "/search?filter_document_type=cma_case"

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

  def test_can_filter_between_dates
    commit_document("mainstream_test", cma_case_attributes)

    get "/search?filter_document_type=cma_case&filter_opened_date=from:2014-03-31,to:2014-04-02"

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
    commit_document("mainstream_test", cma_case_attributes)

    get "/search?filter_document_type=cma_case&filter_opened_date=to:2014-04-02,from:2014-03-31"

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
    commit_document("mainstream_test", cma_case_attributes)

    get "/search?filter_document_type=cma_case&filter_opened_date=from:2014-03-31"

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
    commit_document("mainstream_test", cma_case_attributes)

    get "/search?filter_document_type=cma_case&filter_opened_date=to:2014-04-02"

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
    get "/search?filter_document_type=cma_case&filter_opened_date[]=from:2014-03-31&filter_opened_date[]=to:2014-04-02"

    assert_equal 422, last_response.status
    assert_equal(
      { "error" => %{Too many values (2) for parameter "opened_date" (must occur at most once)} },
      parsed_response,
    )
  end

  def test_cannot_provide_invalid_dates_for_date_filter
    get "/search?filter_document_type=cma_case&filter_opened_date=from:not-a-date"

    assert_equal 422, last_response.status
    assert_equal(
      { "error" => %{Invalid value "not-a-date" for parameter "opened_date" (expected ISO8601 date} },
      parsed_response,
    )
  end

  def test_expandinging_of_organisations
    commit_document("mainstream_test",
      title: 'Advice on Treatment of Dragons',
      link: '/dragon-guide',
      organisations: ['/ministry-of-magic']
    )

    commit_document("government_test",
      slug: '/ministry-of-magic',
      title: 'Ministry of Magic',
      link: '/ministry-of-magic-site',
      format: 'organisation'
    )

    get "/search.json?q=dragons"

    assert_equal first_result['organisations'],
      [{ "slug" => "/ministry-of-magic",
         "link" => "/ministry-of-magic-site",
         "title" => "Ministry of Magic" }]
  end

  def test_expandinging_of_organisations_via_content_id
    commit_document(
      "mainstream_test",
      title: 'Advice on Treatment of Dragons',
      link: '/dragon-guide',
      organisation_content_ids: ['organisation-content-id']
    )

    commit_document(
      "government_test",
      content_id: 'organisation-content-id',
      slug: '/ministry-of-magic',
      title: 'Ministry of Magic',
      link: '/ministry-of-magic-site',
      format: 'organisation'
    )

    get "/search.json?q=dragons"

    # Adds a new key with the expanded organisations
    assert_equal(
      first_result['expanded_organisations'],
      [
        {
          "content_id" => 'organisation-content-id',
          "slug" => '/ministry-of-magic',
          "link" => '/ministry-of-magic-site',
          "title" => 'Ministry of Magic',
        }
      ]
    )

    # Keeps the organisation content ids
    assert_equal(
      first_result['organisation_content_ids'],
      ['organisation-content-id']
    )
  end

  def test_search_for_expanded_organisations_works
    commit_document(
      "mainstream_test",
      title: 'Advice on Treatment of Dragons',
      link: '/dragon-guide',
      organisation_content_ids: ['organisation-content-id']
    )

    commit_document(
      "government_test",
      content_id: 'organisation-content-id',
      slug: '/ministry-of-magic',
      title: 'Ministry of Magic',
      link: '/ministry-of-magic-site',
      format: 'organisation'
    )

    get "/search.json?q=dragons&fields[]=expanded_organisations"

    assert(first_result['expanded_organisations'])
  end

  def test_filter_by_organisation_content_ids_works
    commit_document(
      "mainstream_test",
      title: 'Advice on Treatment of Dragons',
      link: '/dragon-guide',
      organisation_content_ids: ['organisation-content-id']
    )

    commit_document(
      "government_test",
      content_id: 'organisation-content-id',
      slug: '/ministry-of-magic',
      title: 'Ministry of Magic',
      link: '/ministry-of-magic-site',
      format: 'organisation'
    )

    get "/search.json?filter_organisation_content_ids[]=organisation-content-id"

    assert(first_result['expanded_organisations'])
  end

  def test_expandinging_of_topics
    commit_document("mainstream_test",
      title: 'Advice on Treatment of Dragons',
      link: '/dragon-guide',
      topic_content_ids: ['topic-content-id']
    )

    commit_document("government_test",
      content_id: 'topic-content-id',
      slug: 'topic-magic',
      title: 'Magic topic',
      link: '/magic-topic-site',
      # TODO: we should rename this format to `topic` and update all apps
      format: 'specialist_sector'
    )

    get "/search.json?q=dragons"

    # Adds a new key with the expanded topics
    assert_equal(
      first_result['expanded_topics'],
      [
        {
          "content_id" => 'topic-content-id',
          "slug" => "topic-magic",
          "link" => "/magic-topic-site",
          "title" => "Magic topic"
        }
      ]
    )

    # Keeps the topic content ids
    assert_equal(first_result['topic_content_ids'], ['topic-content-id'])
  end

  def test_filter_by_topic_content_ids_works
    commit_document("mainstream_test",
      title: 'Advice on Treatment of Dragons',
      link: '/dragon-guide',
      topic_content_ids: ['topic-content-id']
    )

    commit_document("government_test",
      content_id: 'topic-content-id',
      slug: 'topic-magic',
      title: 'Magic topic',
      link: '/magic-topic-site',
      # TODO: we should rename this format to `topic` and update all apps
      format: 'specialist_sector'
    )
    get "/search.json?filter_topic_content_ids[]=topic-content-id"

    assert(first_result['expanded_topics'])
  end

  def test_id_search
    populate_content_indexes(section_count: 1)

    get "/search?q=id1&debug=new_weighting"

    assert result_links.include? "/mainstream-1"
  end

  def test_withdrawn_content
    commit_document("mainstream_test",
      title: "I am the result",
      description: "This is a test search result",
      link: "/some-nice-link",
      is_withdrawn: true
    )

    get "/search?q=test"
    assert_equal 0, parsed_response.fetch("total")
  end

  def test_withdrawn_content_with_flag
    commit_document("mainstream_test",
      title: "I am the result",
      description: "This is a test search result",
      link: "/some-nice-link",
      is_withdrawn: true
    )

    get "/search?q=test&debug=include_withdrawn&fields[]=is_withdrawn"
    assert_equal 1, parsed_response.fetch("total")
    assert_equal true, parsed_response.dig("results", 0, "is_withdrawn")
  end

  def test_withdrawn_content_with_flag_with_aggregations
    commit_document("mainstream_test",
      title: "I am the result",
      organisation: "Test Org",
      description: "This is a test search result",
      link: "/some-nice-link",
      is_withdrawn: true
    )

    get "/search?q=test&debug=include_withdrawn&aggregate_mainstream_browse_pages=2"
    assert_equal 1, parsed_response.fetch("total")
  end

  def test_show_the_query
    get "/search?q=test&debug=show_query"

    assert parsed_response.fetch("elasticsearch_query")
  end

  def test_dfid_can_search_by_every_aggregate
    commit_document("mainstream_test", dfid_research_output_attributes)

    aggregate_queries = %w(
      filter_dfid_review_status[]=peer_reviewed
      filter_country[]=TZ&filter_country[]=AL
    )

    aggregate_queries.each do |filter_query|
      get "/search?filter_document_type=dfid_research_output&#{filter_query}"

      assert last_response.ok?
      assert_equal 1, parsed_response.fetch("total"), "Failure to search by #{filter_query}"
      assert_equal(
        hash_including(
          "document_type" => dfid_research_output_attributes.fetch("_type"),
          "title" => dfid_research_output_attributes.fetch("title"),
          "link" => dfid_research_output_attributes.fetch("link"),
        ),
        parsed_response.fetch("results").fetch(0),
      )
    end
  end

  def test_taxonomy_can_be_returned
    commit_document("mainstream_test",
      title: "I am the result",
      description: "This is a test search result",
      link: "/some-nice-link",
      taxons: ["eb2093ef-778c-4105-9f33-9aa03d14bc5c"]
    )

    get "/search?q=test&fields[]=taxons"
    assert_equal 1, parsed_response.fetch("total")

    taxons = parsed_response.dig("results", 0, "taxons")
    assert_equal ["eb2093ef-778c-4105-9f33-9aa03d14bc5c"], taxons
  end

  def test_taxonomy_can_be_filtered
    commit_document("mainstream_test",
      title: "I am the result",
      description: "This is a test search result",
      link: "/some-nice-link",
      taxons: ["eb2093ef-778c-4105-9f33-9aa03d14bc5c"]
    )

    get "/search?filter_taxons=eb2093ef-778c-4105-9f33-9aa03d14bc5c"

    assert last_response.ok?
    assert_equal 1, parsed_response.fetch("total")
    assert_equal(
      hash_including(
        "title" => "I am the result",
        "link" => "/some-nice-link",
      ),
      parsed_response.fetch("results").fetch(0),
    )
  end

  def test_taxonomy_can_be_filtered_by_part
    commit_document("mainstream_test",
      title: "I am the result",
      description: "This is a test search result",
      link: "/some-nice-link",
      taxons: ["eb2093ef-778c-4105-9f33-9aa03d14bc5c"],
      part_of_taxonomy_tree: %w(eb2093ef-778c-4105-9f33-9aa03d14bc5c aa2093ef-778c-4105-9f33-9aa03d14bc5c)
    )

    get "/search?filter_part_of_taxonomy_tree=eb2093ef-778c-4105-9f33-9aa03d14bc5c"

    assert last_response.ok?
    assert_equal 1, parsed_response.fetch("total")

    get "/search?filter_part_of_taxonomy_tree=aa2093ef-778c-4105-9f33-9aa03d14bc5c"

    assert last_response.ok?
    assert_equal 1, parsed_response.fetch("total")
  end

private

  def first_result
    @first_result ||= parsed_response['results'].first
  end

  def result_links
    @_result_links ||= parsed_response["results"].map do |result|
      result["link"]
    end
  end

  def result_titles
    @_result_titles ||= parsed_response["results"].map do |result|
      result["title"]
    end
  end

  def cma_case_attributes
    {
      "title" => "Somewhat Unique CMA Case",
      "link" => "/cma-cases/somewhat-unique-cma-case",
      "indexable_content" => "Mergers of cheeses and faces",
      "_type" => "cma_case",
      "specialist_sectors" => ["farming"],
      "opened_date" => "2014-04-01",
    }
  end

  def dfid_research_output_attributes
    {
      "title" => "Somewhat Unique DFID Research Output",
      "link" => "/dfid-research-outputs/somewhat-unique-dfid-research-output",
      "indexable_content" => "Use of calcrete in gender roles in Tanzania",
      "_type" => "dfid_research_output",
      "country" => %w(TZ AL),
      "dfid_review_status" => "peer_reviewed",
      "first_published_at" => "2014-04-02",
    }
  end
end
