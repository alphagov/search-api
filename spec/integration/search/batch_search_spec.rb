require "spec_helper"
require_relative "../../support/search_integration_spec_helper"

RSpec.configure do |c|
  c.include SearchIntegrationSpecHelper
end

RSpec.describe "BatchSearchTest" do
  it "can return multiple distinct results" do
    commit_ministry_of_magic_document
    commit_treatment_of_dragons_document
    get build_get_url([{ q: "ministry of magic" }, { q: "advice on treatment of dragons" }])
    results = parsed_response["results"]
    expect_search_has_result_count(results[0], 1)
    expect_results_includes_ministry_of_magic(results, 0, 0)
    expect_search_has_result_count(results[1], 1)
    expect_results_includes_treatment_of_dragons(results, 1, 0)
  end

  it "spell checking with typo" do
    commit_ministry_of_magic_document
    commit_treatment_of_dragons_document
    get build_get_url([{ q: "ministry of magick" }, { q: "advice on treatment of dragoons" }])
    results = parsed_response["results"]
    expect_search_has_result_count(results[0], 1)
    expect_results_includes_ministry_of_magic(results, 0, 0)
    expect_search_has_result_count(results[1], 1)
    expect_results_includes_treatment_of_dragons(results, 1, 0)
  end

  it "spell checking with blocklisted typo" do
    commit_ministry_of_magic_document
    commit_document(
      "government_test",
      "title" => "Brexitt",
      "description" => "Brexitt",
      "link" => "/brexitt",
    )
    get build_get_url([{ q: "ministry of magic" }, { q: "brexit" }])
    results = parsed_response["results"]
    expect_search_has_result_count(results[0], 1)
    expect_results_includes_ministry_of_magic(results, 0, 0)
    expect_search_has_result_count(results[1], 0)
    expect(results[1]["suggested_queries"]).to eq([])
  end

  it "spell checking without typo" do
    commit_ministry_of_magic_document
    build_sample_documents_on_content_indices(documents_per_index: 1)
    get build_get_url([{ q: "ministry of magic" }, { q: "milliband" }])
    results = parsed_response["results"]
    expect_search_has_result_count(results[0], 1)
    expect_results_includes_ministry_of_magic(results, 0, 0)
    expect_search_has_result_count(results[1], 0)
    expect(results[1]["suggested_queries"]).to eq([])
  end

  it "returns docs from all indexes" do
    commit_ministry_of_magic_document
    build_sample_documents_on_content_indices(documents_per_index: 1)
    get build_get_url([{ q: "ministry of magic" }, { q: "important" }])
    results = parsed_response["results"]
    expect_search_has_result_count(results[0], 1)
    expect_results_includes_ministry_of_magic(results, 0, 0)
    expect_search_has_result_count(results[1], 2)
    result_links = result_links(results[1])
    expect(result_links).to include "/government-1"
    expect(result_links).to include "/govuk-1"
  end

  it "sort by date ascending and descending" do
    build_sample_documents_on_content_indices(documents_per_index: 2)
    get build_get_url([{ q: "important", order: "-public_timestamp" }, { q: "important", order: "public_timestamp" }])
    results = parsed_response["results"]
    first_result_links = result_links(results[0])
    expect(first_result_links.take(2)).to eq(["/government-2", "/government-1"])
    second_result_links = result_links(results[1])
    expect(second_result_links.take(2)).to eq(["/government-1", "/government-2"])
  end

  it "sort by title ascending and descending" do
    build_sample_documents_on_content_indices(documents_per_index: 1)
    get build_get_url([{ order: "-title" }, { order: "title" }])
    results = parsed_response["results"]
    expect(result_titles(results[0])).to eq(["sample govuk document 1", "sample government document 1"])
    expect(result_titles(results[1])).to eq(["sample government document 1", "sample govuk document 1"])
  end

  it "filter and reject by field" do
    build_sample_documents_on_content_indices(documents_per_index: 2)
    get build_get_url([{ filter_mainstream_browse_pages: "browse/page/1" }, { reject_mainstream_browse_pages: "browse/page/1" }])
    results = parsed_response["results"]
    expect(result_links(results[0]).sort).to eq(["/government-1", "/govuk-1"])
    expect(result_links(results[1]).sort).to eq(["/government-2", "/govuk-2"])
  end

  it "can filter for missing field or specific value in field" do
    build_sample_documents_on_content_indices(documents_per_index: 1)
    get build_get_url([{ filter_specialist_sectors: %w[_MISSING"] }, { filter_specialist_sectors: %w[_MISSING farming] }])
    results = parsed_response["results"]
    expect(result_links(results[0]).sort).to eq([])
    expect(result_links(results[1]).sort).to eq(["/government-1", "/govuk-1"])
  end

  it "can filter and reject" do
    build_sample_documents_on_content_indices(documents_per_index: 2)
    get build_get_url([{ reject_mainstream_browse_pages: 1, filter_specialist_sectors: %w[farming] }, { filter_specialist_sectors: %w[_MISSING farming] }])
    results = parsed_response["results"]
    expect(result_links(results[0]).sort).to eq(["/government-2", "/govuk-2"])
    expect(result_links(results[1]).sort).to eq(["/government-1", "/government-2", "/govuk-1", "/govuk-2"])
  end

  it "only contains fields which are present" do
    commit_ministry_of_magic_document
    build_sample_documents_on_content_indices(documents_per_index: 2)
    get build_get_url([{ q: "ministry of magic" }, { q: "important", order: "public_timestamp" }])
    results = parsed_response["results"]
    expect_search_has_result_count(results[0], 1)
    expect_results_includes_ministry_of_magic(results, 0, 0)
    expect_search_has_result_count(results[1], 4)
    expect(results[1]["results"][0]).not_to include("specialist_sectors")
    expect(results[1]["results"][1]["specialist_sectors"]).to eq([{ "slug" => "farming" }])
  end

  it "validates integer params and other valid query also fails" do
    commit_ministry_of_magic_document
    get build_get_url([{ start: "a" }, { start: 10 }])
    expect(last_response.status).to eq(422)
    expect(parsed_response).to eq({ "error" => "Invalid value \"a\" for parameter \"start\" (expected positive integer)" })
  end

  it "allows integer params leading zeros and other valid query also succeeds" do
    build_sample_documents_on_content_indices(documents_per_index: 11)
    get build_get_url([{ start: "0", count: "09" }, { start: "0", count: 10 }])
    expect(last_response).to be_ok
    results = parsed_response["results"]
    expect_search_has_result_count(results[0], 9)
    expect_search_has_result_count(results[1], 10)
  end

  it "validates unknown params and other valid query also fails" do
    commit_ministry_of_magic_document
    get build_get_url([{ foo: "baz", bar: "qux" }, { q: "ministry of magic" }])
    expect(last_response.status).to eq(422)
    expect(parsed_response).to eq({ "error" => "Unexpected parameters: foo, bar" })
  end

  it "debug explain returns explanations" do
    commit_ministry_of_magic_document
    get build_get_url([{ q: "ministry of magic", debug: "explain" }, { q: "ministry of magic" }])
    results = parsed_response["results"]
    expect_search_has_result_count(results[0], 1)
    expect_results_includes_ministry_of_magic(results, 0, 0)
    expect_search_has_result_count(results[1], 1)
    expect_results_includes_ministry_of_magic(results, 1, 0)
    first_results_first_hit_explain = results[0]["results"].first["_explanation"]
    expect(first_results_first_hit_explain).not_to be_nil
    expect(first_results_first_hit_explain.keys).to include("value")
    expect(first_results_first_hit_explain.keys).to include("description")
    expect(first_results_first_hit_explain.keys).to include("details")

    expect(results[1]["results"].first["_explanation"]).to be_nil
  end

  it "can scope by elasticsearch type" do
    commit_ministry_of_magic_document
    commit_document("govuk_test", cma_case_attributes, type: "cma_case")

    get build_get_url([{ filter_document_type: "cma_case" }, { q: "ministry of magic" }])
    results = parsed_response["results"]
    expect_search_has_result_count(results[0], 1)
    expect(results[0]["results"][0]).to match(
      hash_including(
        "document_type" => "cma_case",
        "title" => cma_case_attributes.fetch("title"),
        "link" => cma_case_attributes.fetch("link"),
      ),
    )
    expect_results_includes_ministry_of_magic(results, 1, 0)
  end

  it "can filter between dates" do
    commit_ministry_of_magic_document
    commit_document("govuk_test", cma_case_attributes, type: "cma_case")

    get build_get_url([{ filter_document_type: "cma_case", filter_opened_date: "from:2014-03-31,to:2014-04-02" }, { q: "ministry of magic" }])
    results = parsed_response["results"]
    expect_search_has_result_count(results[0], 1)
    expect(results[0]["results"][0]).to match(
      hash_including(
        "document_type" => "cma_case",
        "title" => cma_case_attributes.fetch("title"),
        "link" => cma_case_attributes.fetch("link"),
      ),
    )
    expect_results_includes_ministry_of_magic(results, 1, 0)
  end

  it "can filter between dates with reversed parameter order" do
    commit_ministry_of_magic_document
    commit_document("govuk_test", cma_case_attributes, type: "cma_case")

    get build_get_url([{ filter_document_type: "cma_case", filter_opened_date: "to:2014-04-02,from:2014-03-31" }, { q: "ministry of magic" }])
    results = parsed_response["results"]
    expect_search_has_result_count(results[0], 1)
    expect(results[0]["results"][0]).to match(
      hash_including(
        "document_type" => "cma_case",
        "title" => cma_case_attributes.fetch("title"),
        "link" => cma_case_attributes.fetch("link"),
      ),
    )
    expect_results_includes_ministry_of_magic(results, 1, 0)
  end

  it "can filter from date" do
    commit_ministry_of_magic_document
    commit_filter_from_date_documents

    get build_get_url([{ filter_document_type: "cma_case", filter_opened_date: "from:2014-03-31" }, { q: "ministry of magic" }])
    results = parsed_response["results"]

    expect_response_includes_matching_date_and_datetime_results(results[0]["results"])
    expect_results_includes_ministry_of_magic(results, 1, 0)
  end

  it "can filter from time" do
    commit_ministry_of_magic_document
    commit_filter_from_time_documents

    get build_get_url([{ filter_document_type: "cma_case", filter_opened_date: "from:2014-03-31 14:00:00" }, { q: "ministry of magic" }])
    results = parsed_response["results"]

    expect_response_includes_matching_date_and_datetime_results(results[0]["results"])
    expect_results_includes_ministry_of_magic(results, 1, 0)
  end

  it "can filter to date" do
    commit_ministry_of_magic_document
    commit_filter_to_date_documents

    get build_get_url([{ filter_document_type: "cma_case", filter_opened_date: "to:2014-04-02" }, { q: "ministry of magic" }])
    results = parsed_response["results"]

    expect_response_includes_matching_date_and_datetime_results(results[0]["results"])
    expect_results_includes_ministry_of_magic(results, 1, 0)
  end

  it "can filter to time" do
    commit_ministry_of_magic_document
    commit_filter_to_time_documents

    get build_get_url([{ filter_document_type: "cma_case", filter_opened_date: "to:2014-04-02 11:00:00" }, { q: "ministry of magic" }])
    results = parsed_response["results"]

    expect_response_includes_matching_date_and_datetime_results(results[0]["results"])
    expect_results_includes_ministry_of_magic(results, 1, 0)
  end

  it "can filter times in different time zones" do
    commit_ministry_of_magic_document
    commit_document(
      "govuk_test",
      cma_case_attributes("opened_date" => "2017-07-01T11:20:00.000-03:00", "link" => "/cma-1"),
      type: "cma_case",
    )
    commit_document(
      "govuk_test",
      cma_case_attributes("opened_date" => "2017-07-02T00:15:00.000+01:00", "link" => "/cma-2"),
      type: "cma_case",
    )

    get build_get_url([{ filter_document_type: "cma_case", filter_opened_date: "from:2017-07-01 12:00,to:2017-07-01 23:30:00" }, { q: "ministry of magic" }])
    results = parsed_response["results"]

    expect(results[0]["results"]).to contain_exactly(
      hash_including("link" => "/cma-1"),
      hash_including("link" => "/cma-2"),
    )
    expect_results_includes_ministry_of_magic(results, 1, 0)
  end

  it "cannot provide date filter key multiple times" do
    get build_get_url([{ filter_document_type: "cma_case", filter_opened_date: ["from:2014-03-31", "to:2014-04-02"] }, { q: "ministry of magic" }])

    expect(last_response.status).to eq(422)
    expect(parsed_response).to eq({ "error" => %{Too many values (2) for parameter "opened_date" (must occur at most once)} })
  end

  it "cannot provide invalid dates for date filter" do
    get build_get_url([{ filter_document_type: "cma_case", filter_opened_date: "from:not-a-date" }, { q: "ministry of magic" }])

    expect(last_response.status).to eq(422)
    expect(parsed_response).to eq({ "error" => %{Invalid "from" value "not-a-date" for parameter "opened_date" (expected ISO8601 date)} })
  end

  it "expands organisations" do
    commit_treatment_of_dragons_document({ "organisations" => ["/ministry-of-magic"] })
    commit_ministry_of_magic_document({ "format" => "organisation" })
    get build_get_url([{ q: "dragons" }, { q: "ministry of magic" }])
    results = parsed_response["results"]
    expect(results[0]["results"][0]["organisations"]).to eq(
      [{ "slug" => "/ministry-of-magic",
         "link" => "/ministry-of-magic-site",
         "title" => "Ministry of Magic" }],
    )
    expect_results_includes_ministry_of_magic(results, 1, 0)
  end

  it "expands organisations via content_id" do
    commit_treatment_of_dragons_document({ "organisation_content_ids" => %w[organisation-content-id] })
    commit_ministry_of_magic_document({ "content_id" => "organisation-content-id", "format" => "organisation" })

    get build_get_url([{ q: "dragons" }, { q: "ministry of magic" }])
    results = parsed_response["results"]

    expect_result_includes_ministry_of_magic_for_key(results[0]["results"][0], "expanded_organisations", "content_id" => "organisation-content-id")

    # Keeps the organisation content ids
    expect(
      results[0]["results"][0]["organisation_content_ids"],
    ).to eq(
      %w[organisation-content-id],
    )

    expect_results_includes_ministry_of_magic(results, 1, 0)
  end

  it "search for expanded organisations works" do
    commit_treatment_of_dragons_document({ "organisation_content_ids" => %w[organisation-content-id] })
    commit_ministry_of_magic_document({ "content_id" => "organisation-content-id", "format" => "organisation" })

    get build_get_url([{ q: "dragons", fields: %w[expanded_organisations] }, { q: "ministry of magic" }])
    results = parsed_response["results"]

    expect_result_includes_ministry_of_magic_for_key(results[0]["results"][0], "expanded_organisations", "content_id" => "organisation-content-id")
    expect_results_includes_ministry_of_magic(results, 1, 0)
  end

  it "filter by organisation content_ids works" do
    commit_treatment_of_dragons_document({ "organisation_content_ids" => %w[organisation-content-id] })
    commit_ministry_of_magic_document({ "content_id" => "organisation-content-id", "format" => "organisation" })

    get build_get_url([{ filter_organisation_content_ids: "organisation-content-id" }, { q: "ministry of magic" }])
    results = parsed_response["results"]

    expect_result_includes_ministry_of_magic_for_key(results[0]["results"][0], "expanded_organisations", "content_id" => "organisation-content-id")
    expect_results_includes_ministry_of_magic(results, 1, 0)
  end

  it "expands topics" do
    commit_ministry_of_magic_document
    commit_treatment_of_dragons_document({ "topic_content_ids" => %w[topic-content-id] })
    commit_ministry_of_magic_document({ "index" => "govuk_test",
                                        "content_id" => "topic-content-id",
                                        "slug" => "topic-magic",
                                        "title" => "Magic topic",
                                        "link" => "/magic-topic-site",
                                        # TODO: we should rename this format to `topic` and update all apps
                                        "format" => "specialist_sector" })

    get build_get_url([{ q: "dragons" }, { q: "ministry of magic" }])
    results = parsed_response["results"]

    expect_result_includes_ministry_of_magic_for_key(
      results[0]["results"][0],
      "expanded_topics",
      {
        "content_id" => "topic-content-id",
        "slug" => "topic-magic",
        "link" => "/magic-topic-site",
        "title" => "Magic topic",
      },
    )

    # Keeps the topic content ids
    expect(results[0]["results"][0]["topic_content_ids"]).to eq(%w[topic-content-id])
    expect_results_includes_ministry_of_magic(results, 1, 0)
  end

  it "filter by topic content_ids works" do
    commit_ministry_of_magic_document
    commit_treatment_of_dragons_document({ "topic_content_ids" => %w[topic-content-id] })
    commit_ministry_of_magic_document({ "index" => "govuk_test",
                                        "content_id" => "topic-content-id",
                                        "slug" => "topic-magic",
                                        "title" => "Magic topic",
                                        "link" => "/magic-topic-site",
                                        # TODO: we should rename this format to `topic` and update all apps
                                        "format" => "specialist_sector" })

    get build_get_url([{ filter_topic_content_ids: %w[topic-content-id] }, { q: "ministry of magic" }])
    results = parsed_response["results"]

    expect(results[0]["results"][0]["topic_content_ids"]).to eq(%w[topic-content-id])
    expect_results_includes_ministry_of_magic(results, 1, 0)
  end

  it "will not return withdrawn content" do
    commit_ministry_of_magic_document
    commit_treatment_of_dragons_document({ "is_withdrawn" => true })

    get build_get_url([{ q: "Advice on Treatment of Dragons" }, { q: "ministry of magic" }])
    results = parsed_response["results"]

    expect_search_has_result_count(results[0], 0)
    expect_results_includes_ministry_of_magic(results, 1, 0)
  end

  it "will return withdrawn content with flag" do
    commit_ministry_of_magic_document
    commit_treatment_of_dragons_document({ "is_withdrawn" => true })

    get build_get_url([{ q: "Advice on Treatment of Dragons", debug: "include_withdrawn", fields: %w[is_withdrawn] }, { q: "ministry of magic" }])
    results = parsed_response["results"]

    expect_search_has_result_count(results[0], 1)
    expect(results[0].dig("results", 0, "is_withdrawn")).to be true
    expect_results_includes_ministry_of_magic(results, 1, 0)
  end

  it "will return withdrawn content with flag with aggregations" do
    commit_ministry_of_magic_document
    commit_treatment_of_dragons_document({ "is_withdrawn" => true })

    get build_get_url([{ q: "Advice on Treatment of Dragons", debug: "include_withdrawn", aggregate_mainstream_browse_pages: 2 }, { q: "ministry of magic" }])
    results = parsed_response["results"]

    expect_results_includes_treatment_of_dragons(results, 0, 0)
    expect_results_includes_ministry_of_magic(results, 1, 0)
  end

  it "will show the query" do
    commit_ministry_of_magic_document

    get build_get_url([{ q: "Ministry of Magic", debug: "show_query" }, { q: "ministry of magic" }])
    results = parsed_response["results"]

    expect(results[0].fetch("elasticsearch_query")).to be_truthy
    expect(results[1].dig("elasticsearch_query")).to be_falsy
    expect_results_includes_ministry_of_magic(results, 0, 0)
    expect_results_includes_ministry_of_magic(results, 1, 0)
  end

  it "can return the taxonomy" do
    commit_ministry_of_magic_document("taxons" => %w[eb2093ef-778c-4105-9f33-9aa03d14bc5c])

    get build_get_url([{ q: "Ministry of Magic", fields: %w[taxons] }, { q: "ministry of magic" }])
    results = parsed_response["results"]

    expect(results[0]["results"][0].fetch("taxons")).to eq(%w[eb2093ef-778c-4105-9f33-9aa03d14bc5c])
    expect(results[1].dig("results", 0, "taxons")).to be_falsy
    expect_results_includes_ministry_of_magic(results, 1, 0)
  end

  it "can filter by taxonomy" do
    commit_ministry_of_magic_document("taxons" => %w[eb2093ef-778c-4105-9f33-9aa03d14bc5c])
    commit_treatment_of_dragons_document("taxons" => %w[some-other-taxon])

    get build_get_url([{ filter_taxons: %w[eb2093ef-778c-4105-9f33-9aa03d14bc5c] }, { filter_taxons: %w[eb2093ef-778c-4105-9f33-9aa03d14bc5c some-other-taxon] }])
    results = parsed_response["results"]

    expect_results_includes_ministry_of_magic(results, 1, 0)

    expect_search_has_result_count(results[0], 1)
    expect_results_includes_ministry_of_magic(results, 0, 0)

    expect_search_has_result_count(results[1], 2)
    expect_results_includes_ministry_of_magic(results, 1, 0)
    expect_results_includes_treatment_of_dragons(results, 1, 1)
  end

  it "can filter by part of taxonomy" do
    commit_treatment_of_dragons_document
    commit_ministry_of_magic_document(
      {
        "taxons" => %w[eb2093ef-778c-4105-9f33-9aa03d14bc5c],
        "part_of_taxonomy_tree" => %w[eb2093ef-778c-4105-9f33-9aa03d14bc5c aa2093ef-778c-4105-9f33-9aa03d14bc5c],
      },
    )

    get build_get_url([{ filter_part_of_taxonomy_tree: %w[eb2093ef-778c-4105-9f33-9aa03d14bc5c] }, { filter_part_of_taxonomy_tree: %w[aa2093ef-778c-4105-9f33-9aa03d14bc5c] }])
    results = parsed_response["results"]

    expect_search_has_result_count(results[0], 1)
    expect_results_includes_ministry_of_magic(results, 0, 0)
    expect_search_has_result_count(results[1], 1)
    expect_results_includes_ministry_of_magic(results, 1, 0)
  end

  it "can filter by facet groups" do
    commit_treatment_of_dragons_document
    commit_ministry_of_magic_document(
      {
        "facet_groups" => %w[eb2093ef-778c-4105-9f33-9aa03d14bc5c aa2093ef-778c-4105-9f33-9aa03d14bc5c],
      },
    )

    get build_get_url([{ filter_facet_groups: %w[eb2093ef-778c-4105-9f33-9aa03d14bc5c] }, { filter_facet_groups: %w[aa2093ef-778c-4105-9f33-9aa03d14bc5c] }])
    results = parsed_response["results"]

    expect_search_has_result_count(results[0], 1)
    expect_results_includes_ministry_of_magic(results, 0, 0)
    expect_search_has_result_count(results[1], 1)
    expect_results_includes_ministry_of_magic(results, 1, 0)
  end

  it "can filter by facet values" do
    commit_treatment_of_dragons_document
    commit_ministry_of_magic_document(
      {
        "facet_values" => %w[eb2093ef-778c-4105-9f33-9aa03d14bc5c aa2093ef-778c-4105-9f33-9aa03d14bc5c],
      },
    )

    get build_get_url([{ filter_facet_values: %w[eb2093ef-778c-4105-9f33-9aa03d14bc5c] }, { filter_facet_values: %w[aa2093ef-778c-4105-9f33-9aa03d14bc5c] }])
    results = parsed_response["results"]

    expect_search_has_result_count(results[0], 1)
    expect_results_includes_ministry_of_magic(results, 0, 0)
    expect_search_has_result_count(results[1], 1)
    expect_results_includes_ministry_of_magic(results, 1, 0)
  end

  it "will allow ten searches" do
    commit_ministry_of_magic_document
    searches = 10.times.map do
      { q: "Ministry of Magic" }
    end
    get build_get_url(searches)
    results = parsed_response["results"]
    10.times do |search_number|
      expect_search_has_result_count(results[search_number], 1)
      expect_results_includes_ministry_of_magic(results, search_number, 0)
    end
  end

  it "return 400 response for 11 searches" do
    commit_ministry_of_magic_document
    searches = 11.times.map do
      { q: "Ministry of Magic" }
    end
    get build_get_url(searches)
    expect(last_response).to be_bad_request
    expect(last_response.body).to eq("Maximum of 10 searches per batch")
  end

  it "will do something in response to a SQL injection attack" do
    commit_ministry_of_magic_document
    page_sql_injection_parameter = "21111111111111%22%20UNION%20SELECT%20CHAR(45,120,49,45,81,45),CHAR(45,120,50,45,81,45),CHAR(45,120,51,45,81,45),CHAR(45,120,52,45,81,45),CHAR(45,120,53,45,81,45),CHAR(45,120,54,45,81,45),CHAR(45,120,55,45,81,45),CHAR(45,120,56,45,81,45),CHAR(45,120,57,45,81,45),CHAR(45,120,49,48,45,81,45),CHAR(45,120,49,49,45,81,45),CHAR(45,120,49,50,45,81,45),CHAR(45,120,49,51,45,81,45),CHAR(45,120,49,52,45,81,45),CHAR(45,120,49,53,45,81,45),CHAR(45,120,49,54,45,81,45),CHAR(45,120,49,55,45,81,45),CHAR(45,120,49,56,45,81,45),CHAR(45,120,49,57,45,81,45),CHAR(45,120,50,48,45,81,45),CHAR(45,120,50,49,45,81,45),CHAR(45,120,50,50,45,81,45),CHAR(45,120,50,51,45,81,45),CHAR(45,120,50,52,45,81,45),CHAR(45,120,50,53,45,81,45)%20--%20/*%20"
    get build_get_url([{ q: "Ministry of Magic", count: page_sql_injection_parameter }, { q: "Ministry of Magic" }])
    expect(last_response.body).to eq("{\"error\":\"Invalid value \\\"21111111111111%22%20UNION%20SELECT%20CHAR(45,120,49,45,81,45),CHAR(45,120,50,45,81,45),CHAR(45,120,51,45,81,45),CHAR(45,120,52,45,81,45),CHAR(45,120,53,45,81,45),CHAR(45,120,54,45,81,45),CHAR(45,120,55,45,81,45),CHAR(45,120,56,45,81,45),CHAR(45,120,57,45,81,45),CHAR(45,120,49,48,45,81,45),CHAR(45,120,49,49,45,81,45),CHAR(45,120,49,50,45,81,45),CHAR(45,120,49,51,45,81,45),CHAR(45,120,49,52,45,81,45),CHAR(45,120,49,53,45,81,45),CHAR(45,120,49,54,45,81,45),CHAR(45,120,49,55,45,81,45),CHAR(45,120,49,56,45,81,45),CHAR(45,120,49,57,45,81,45),CHAR(45,120,50,48,45,81,45),CHAR(45,120,50,49,45,81,45),CHAR(45,120,50,50,45,81,45),CHAR(45,120,50,51,45,81,45),CHAR(45,120,50,52,45,81,45),CHAR(45,120,50,53,45,81,45)%20--%20/*%20\\\" for parameter \\\"count\\\" (expected positive integer)\"}")
  end

private

  def expect_search_has_result_count(results, count)
    expect(results["results"].count).to eq(count)
  end

  def expect_results_includes_ministry_of_magic(results, expected_result_set_index, expected_result_index)
    expect_results_includes(results[expected_result_set_index], expected_result_index, title: "Ministry of Magic", link: "/ministry-of-magic-site")
  end

  def expect_results_includes_treatment_of_dragons(results, expected_result_set_index, expected_result_index)
    expect_results_includes(results[expected_result_set_index], expected_result_index, title: "Advice on Treatment of Dragons", link: "/dragon-guide")
  end

  def expect_results_includes(results, index, expected_results)
    actual_result = results["results"][index]
    expected_results.each_pair do |key, expected_result|
      expect(actual_result[key.to_s]).to eq(expected_result)
    end
  end

  def result_links(results)
    results["results"].map { |result| result["link"] }
  end

  def result_titles(results)
    results["results"].map { |result| result["title"].downcase }
  end

  def build_get_url(searches)
    url_friendly_searches = []
    searches.each_with_index do |search, index|
      url_friendly_search = {}
      url_friendly_search[index] = search
      url_friendly_searches << url_friendly_search
    end
    searches_query = { search: url_friendly_searches }
    search_parameters = Rack::Utils.build_nested_query(searches_query)
    "/batch_search?#{search_parameters}"
  end
end
