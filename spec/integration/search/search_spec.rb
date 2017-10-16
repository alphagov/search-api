require 'spec_helper'

RSpec.describe 'SearchTest' do
  it "returns_success" do
    get "/search?q=important"

    expect(last_response).to be_ok
  end

  it "id_code_with_space" do
    # when debug mode includes "use_id_codes" and it searches for
    # "P 60" instead of "P60" a P60 document should be found!

    commit_document(
      "mainstream_test",
      "title" => "Get P45, P60 and other forms for your employees",
      "description" => "Get PAYE forms from HMRC including P45, P60, starter checklist (which replaced the P46), P11D(b)",
      "link" => "/get-paye-forms-p45-p60"

    )

    get "/search?q=p+60&debug=use_id_codes"

    expect(parsed_response['results'].size).to eq(1)
    expect(parsed_response["results"][0]["link"]).to eq("/get-paye-forms-p45-p60")

    get "/search?q=p+60"
    expect(parsed_response['results'].size).to eq(0)
  end

  it "spell_checking_with_typo" do
    commit_document("mainstream_test",
      "title" => "I am the result",
      "description" => "This is a test search result",
      "link" => "/some-nice-link"
    )

    get "/search?q=serch&suggest=spelling"

    expect(parsed_response['suggested_queries']).to eq(['search'])
  end

  it "spell_checking_with_blacklisted_typo" do
    commit_document("mainstream_test",
      "title" => "Brexitt",
      "description" => "Brexitt",
      "link" => "/brexitt")

    get "/search?q=brexit&suggest=spelling"

    expect(parsed_response['suggested_queries']).to eq([])
  end

  it "spell_checking_without_typo" do
    populate_content_indexes(section_count: 1)

    get "/search?q=milliband"

    expect(parsed_response['suggested_queries']).to eq([])
  end

  it "returns_docs_from_all_indexes" do
    populate_content_indexes(section_count: 1)

    get "/search?q=important"

    expect(result_links).to include "/government-1"
    expect(result_links).to include "/mainstream-1"
  end

  it "sort_by_date_ascending" do
    populate_content_indexes(section_count: 2)

    get "/search?q=important&order=public_timestamp"

    expect(result_links.take(2)).to eq(["/government-1", "/government-2"])
  end

  it "sort_by_date_descending" do
    populate_content_indexes(section_count: 2)

    get "/search?q=important&order=-public_timestamp"

    # The government links have dates, so appear before all the other links.
    # The other documents have no dates, so appear in an undefined order
    expect(result_links.take(2)).to eq(["/government-2", "/government-1"])
  end

  it "sort_by_title_ascending" do
    populate_content_indexes(section_count: 1)

    get "/search?order=title"
    lowercase_titles = result_titles.map(&:downcase)

    expect(lowercase_titles).to eq(lowercase_titles.sort)
  end

  it "filter_by_field" do
    populate_content_indexes(section_count: 1)

    get "/search?filter_mainstream_browse_pages=browse/page/1"

    expect(result_links.sort).to eq(["/government-1", "/mainstream-1"])
  end

  it "reject_by_field" do
    populate_content_indexes(section_count: 2)

    get "/search?reject_mainstream_browse_pages=browse/page/1"

    expect(result_links.sort).to eq(["/government-2", "/mainstream-2"])
  end

  it "can_filter_for_missing_field" do
    populate_content_indexes(section_count: 1)

    get "/search?filter_specialist_sectors=_MISSING"

    expect(result_links.sort).to eq(["/government-1", "/mainstream-1"])
  end

  it "can_filter_for_missing_or_specific_value_in_field" do
    populate_content_indexes(section_count: 1)

    get "/search?filter_specialist_sectors[]=_MISSING&filter_specialist_sectors[]=farming"

    expect(result_links.sort).to eq(["/government-1", "/mainstream-1"])
  end

  it "can_filter_and_reject" do
    populate_content_indexes(section_count: 2)

    get "/search?reject_mainstream_browse_pages=1&filter_specialist_sectors[]=farming"

    expect([
      "/government-2",
      "/mainstream-2",
    ]).to eq(result_links.sort)
  end

  it "only_contains_fields_which_are_present" do
    populate_content_indexes(section_count: 2)

    get "/search?q=important&order=public_timestamp"

    results = parsed_response["results"]
    expect(results[0].keys).not_to include("specialist_sectors")
    expect(results[1]["specialist_sectors"]).to eq([{ "slug" => "farming" }])
  end

  it "validates_integer_params" do
    get "/search?start=a"

    expect(last_response.status).to eq(422)
    expect(parsed_response).to eq({ "error" => "Invalid value \"a\" for parameter \"start\" (expected positive integer)" })
  end

  it "allows_integer_params_leading_zeros" do
    get "/search?start=09"

    expect(last_response).to be_ok
  end

  it "validates_unknown_params" do
    get "/search?foo&bar=1"

    expect(last_response.status).to eq(422)
    expect(parsed_response).to eq("error" => "Unexpected parameters: foo, bar")
  end

  it "debug_explain_returns_explanations" do
    populate_content_indexes(section_count: 1)

    get "/search?debug=explain"

    first_hit_explain = parsed_response["results"].first["_explanation"]
    expect(first_hit_explain).not_to be_nil
    expect(first_hit_explain.keys).to include("value")
    expect(first_hit_explain.keys).to include("description")
    expect(first_hit_explain.keys).to include("details")
  end

  it "can_scope_by_elasticsearch_type" do
    commit_document("mainstream_test", cma_case_attributes, type: "cma_case")

    get "/search?filter_document_type=cma_case"

    expect(last_response).to be_ok
    expect(parsed_response.fetch("total")).to eq(1)
    expect(
      hash_including(
        "document_type" => "cma_case",
        "title" => cma_case_attributes.fetch("title"),
        "link" => cma_case_attributes.fetch("link"),
      )
    ).to eq(
      parsed_response.fetch("results").fetch(0),
    )
  end

  it "can_filter_between_dates" do
    commit_document("mainstream_test", cma_case_attributes, type: "cma_case")

    get "/search?filter_document_type=cma_case&filter_opened_date=from:2014-03-31,to:2014-04-02"

    expect(last_response).to be_ok
    expect(parsed_response.fetch("total")).to eq(1)
    expect(
      hash_including(
        "title" => cma_case_attributes.fetch("title"),
        "link" => cma_case_attributes.fetch("link"),
      )
    ).to eq(
      parsed_response.fetch("results").fetch(0),
    )
  end

  it "can_filter_between_dates_with_reversed_parameter_order" do
    commit_document("mainstream_test", cma_case_attributes, type: "cma_case")

    get "/search?filter_document_type=cma_case&filter_opened_date=to:2014-04-02,from:2014-03-31"

    expect(last_response).to be_ok
    expect(parsed_response.fetch("total")).to eq(1)
    expect(
      hash_including(
        "title" => cma_case_attributes.fetch("title"),
        "link" => cma_case_attributes.fetch("link"),
      )
    ).to eq(
      parsed_response.fetch("results").fetch(0),
    )
  end

  it "can_filter_from_date" do
    commit_document("mainstream_test", cma_case_attributes, type: "cma_case")

    get "/search?filter_document_type=cma_case&filter_opened_date=from:2014-03-31"

    expect(last_response).to be_ok
    expect(parsed_response.fetch("total")).to eq(1)
    expect(
      hash_including(
        "title" => cma_case_attributes.fetch("title"),
        "link" => cma_case_attributes.fetch("link"),
      )
    ).to eq(
      parsed_response.fetch("results").fetch(0),
    )
  end

  it "can_filter_to_date" do
    commit_document("mainstream_test", cma_case_attributes, type: "cma_case")

    get "/search?filter_document_type=cma_case&filter_opened_date=to:2014-04-02"

    expect(last_response).to be_ok
    expect(parsed_response.fetch("total")).to eq(1)
    expect(
      hash_including(
        "title" => cma_case_attributes.fetch("title"),
        "link" => cma_case_attributes.fetch("link"),
      )
    ).to eq(
      parsed_response.fetch("results").fetch(0),
    )
  end

  it "cannot_provide_date_filter_key_multiple_times" do
    get "/search?filter_document_type=cma_case&filter_opened_date[]=from:2014-03-31&filter_opened_date[]=to:2014-04-02"

    expect(last_response.status).to eq(422)
    expect(
      { "error" => %{Too many values (2) for parameter "opened_date" (must occur at most once)} }
    ).to eq(
      parsed_response,
    )
  end

  it "cannot_provide_invalid_dates_for_date_filter" do
    get "/search?filter_document_type=cma_case&filter_opened_date=from:not-a-date"

    expect(last_response.status).to eq(422)
    expect(
      { "error" => %{Invalid value "not-a-date" for parameter "opened_date" (expected ISO8601 date} }
    ).to eq(
      parsed_response,
    )
  end

  it "expandinging_of_organisations" do
    commit_document("mainstream_test",
      "title" => 'Advice on Treatment of Dragons',
      "link" => '/dragon-guide',
      "organisations" => ['/ministry-of-magic']
    )

    commit_document("government_test",
      "slug" => '/ministry-of-magic',
      "title" => 'Ministry of Magic',
      "link" => '/ministry-of-magic-site',
      "format" => 'organisation'
    )

    get "/search.json?q=dragons"

    expect(first_result['organisations']).to eq(
      [{ "slug" => "/ministry-of-magic",
         "link" => "/ministry-of-magic-site",
         "title" => "Ministry of Magic" }]
    )
  end

  it "expandinging_of_organisations_via_content_id" do
    commit_document(
      "mainstream_test",
      "title" => 'Advice on Treatment of Dragons',
      "link" => '/dragon-guide',
      "organisation_content_ids" => ['organisation-content-id']
    )

    commit_document(
      "government_test",
      "content_id" => 'organisation-content-id',
      "slug" => '/ministry-of-magic',
      "title" => 'Ministry of Magic',
      "link" => '/ministry-of-magic-site',
      "format" => 'organisation'
    )

    get "/search.json?q=dragons"

    # Adds a new key with the expanded organisations
    expect(
      first_result['expanded_organisations']
    ).to eq(
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
    expect(
      first_result['organisation_content_ids']
    ).to eq(
      ['organisation-content-id']
    )
  end

  it "search_for_expanded_organisations_works" do
    commit_document(
      "mainstream_test",
      "title" => 'Advice on Treatment of Dragons',
      "link" => '/dragon-guide',
      "organisation_content_ids" => ['organisation-content-id']
    )

    commit_document(
      "government_test",
      "content_id" => 'organisation-content-id',
      "slug" => '/ministry-of-magic',
      "title" => 'Ministry of Magic',
      "link" => '/ministry-of-magic-site',
      "format" => 'organisation'
    )

    get "/search.json?q=dragons&fields[]=expanded_organisations"

    expect(first_result['expanded_organisations']).to be_truthy
  end

  it "filter_by_organisation_content_ids_works" do
    commit_document(
      "mainstream_test",
      "title" => 'Advice on Treatment of Dragons',
      "link" => '/dragon-guide',
      "organisation_content_ids" => ['organisation-content-id']
    )

    commit_document(
      "government_test",
      "content_id" => 'organisation-content-id',
      "slug" => '/ministry-of-magic',
      "title" => 'Ministry of Magic',
      "link" => '/ministry-of-magic-site',
      "format" => 'organisation'
    )

    get "/search.json?filter_organisation_content_ids[]=organisation-content-id"

    expect(first_result['expanded_organisations']).to be_truthy
  end

  it "expandinging_of_topics" do
    commit_document("mainstream_test",
      "title" => 'Advice on Treatment of Dragons',
      "link" => '/dragon-guide',
      "topic_content_ids" => ['topic-content-id']
    )

    commit_document("government_test",
      "content_id" => 'topic-content-id',
      "slug" => 'topic-magic',
      "title" => 'Magic topic',
      "link" => '/magic-topic-site',
      # TODO: we should rename this format to `topic` and update all apps
      "format" => 'specialist_sector'
    )

    get "/search.json?q=dragons"

    # Adds a new key with the expanded topics
    expect(
      first_result['expanded_topics']
    ).to eq(
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
    expect(first_result['topic_content_ids']).to eq(['topic-content-id'])
  end

  it "filter_by_topic_content_ids_works" do
    commit_document("mainstream_test",
      "title" => 'Advice on Treatment of Dragons',
      "link" => '/dragon-guide',
      "topic_content_ids" => ['topic-content-id']
    )

    commit_document("government_test",
      "content_id" => 'topic-content-id',
      "slug" => 'topic-magic',
      "title" => 'Magic topic',
      "link" => '/magic-topic-site',
      # TODO: we should rename this format to `topic` and update all apps
      "format" => 'specialist_sector'
    )
    get "/search.json?filter_topic_content_ids[]=topic-content-id"

    expect(first_result['expanded_topics']).to be_truthy
  end

  it "id_search" do
    populate_content_indexes(section_count: 1)

    get "/search?q=id1&debug=new_weighting"

    expect(result_links).to include "/mainstream-1"
  end

  it "withdrawn_content" do
    commit_document("mainstream_test",
      "title" => "I am the result",
      "description" => "This is a test search result",
      "link" => "/some-nice-link",
      "is_withdrawn" => true
    )

    get "/search?q=test"
    expect(parsed_response.fetch("total")).to eq(0)
  end

  it "withdrawn_content_with_flag" do
    commit_document("mainstream_test",
      "title" => "I am the result",
      "description" => "This is a test search result",
      "link" => "/some-nice-link",
      "is_withdrawn" => true
    )

    get "/search?q=test&debug=include_withdrawn&fields[]=is_withdrawn"
    expect(parsed_response.fetch("total")).to eq(1)
    expect(parsed_response.dig("results", 0, "is_withdrawn")).to be true
  end

  it "withdrawn_content_with_flag_with_aggregations" do
    commit_document("mainstream_test",
      "title" => "I am the result",
      "organisation" => "Test Org",
      "description" => "This is a test search result",
      "link" => "/some-nice-link",
      "is_withdrawn" => true
    )

    get "/search?q=test&debug=include_withdrawn&aggregate_mainstream_browse_pages=2"
    expect(parsed_response.fetch("total")).to eq(1)
  end

  it "show_the_query" do
    get "/search?q=test&debug=show_query"

    expect(parsed_response.fetch("elasticsearch_query")).to be_truthy
  end

  it "taxonomy_can_be_returned" do
    commit_document("mainstream_test",
      "title" => "I am the result",
      "description" => "This is a test search result",
      "link" => "/some-nice-link",
      "taxons" => ["eb2093ef-778c-4105-9f33-9aa03d14bc5c"]
    )

    get "/search?q=test&fields[]=taxons"
    expect(parsed_response.fetch("total")).to eq(1)

    taxons = parsed_response.dig("results", 0, "taxons")
    expect(taxons).to eq(["eb2093ef-778c-4105-9f33-9aa03d14bc5c"])
  end

  it "taxonomy_can_be_filtered" do
    commit_document("mainstream_test",
      "title" => "I am the result",
      "description" => "This is a test search result",
      "link" => "/some-nice-link",
      "taxons" => ["eb2093ef-778c-4105-9f33-9aa03d14bc5c"]
    )

    get "/search?filter_taxons=eb2093ef-778c-4105-9f33-9aa03d14bc5c"

    expect(last_response).to be_ok
    expect(parsed_response.fetch("total")).to eq(1)
    expect(
      hash_including(
        "title" => "I am the result",
        "link" => "/some-nice-link",
      )
    ).to eq(
      parsed_response.fetch("results").fetch(0),
    )
  end

  it "taxonomy_can_be_filtered_by_part" do
    commit_document("mainstream_test",
      "title" => "I am the result",
      "description" => "This is a test search result",
      "link" => "/some-nice-link",
      "taxons" => ["eb2093ef-778c-4105-9f33-9aa03d14bc5c"],
      "part_of_taxonomy_tree" => %w(eb2093ef-778c-4105-9f33-9aa03d14bc5c aa2093ef-778c-4105-9f33-9aa03d14bc5c)
    )

    get "/search?filter_part_of_taxonomy_tree=eb2093ef-778c-4105-9f33-9aa03d14bc5c"

    expect(last_response).to be_ok
    expect(parsed_response.fetch("total")).to eq(1)

    get "/search?filter_part_of_taxonomy_tree=aa2093ef-778c-4105-9f33-9aa03d14bc5c"

    expect(last_response).to be_ok
    expect(parsed_response.fetch("total")).to eq(1)
  end

  it "return_400_response_for_integers_out_of_range" do
    get '/search.json?count=50&start=7599999900'

    expect(last_response).to be_bad_request
    expect(last_response.body).to eq('Integer value of 7599999900 exceeds maximum allowed')
  end

  it "return_400_response_for_query_term_length_too_long" do
    terms = 1025.times.map { ('a'..'z').to_a.sample(5).join }.join(' ')
    get "/search.json?q=#{terms}"

    expect(last_response).to be_bad_request
    expect(last_response.body).to eq('Query must be less than 1024 words')
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
      "specialist_sectors" => ["farming"],
      "opened_date" => "2014-04-01",
    }
  end
end
