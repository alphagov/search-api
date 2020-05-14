require "spec_helper"
require_relative "../../support/search_integration_spec_helper"

RSpec.configure do |c|
  c.include SearchIntegrationSpecHelper
end

RSpec.describe "SearchTest" do
  it "returns success" do
    get "/search?q=important"

    expect(last_response).to be_ok
  end

  it "spell checking with typo" do
    commit_ministry_of_magic_document

    get "/search?q=ministry of magick&suggest=spelling"

    expect(parsed_response["suggested_queries"]).to eq(["ministry of magic"])
  end

  it "highlights spelling suggestions" do
    commit_ministry_of_magic_document

    get "/search?q=ministry of magick&suggest=spelling_with_highlighting"

    expect(parsed_response["suggested_queries"]).to eq([{
      "text" => "ministry of magic",
      "highlighted" => "ministry of <mark>magic</mark>",
    }])
  end

  it "spell checking with blocklisted typo" do
    commit_document(
      "government_test",
      "title" => "Brexitt",
      "description" => "Brexitt",
      "link" => "/brexitt",
    )

    get "/search?q=brexit&suggest=spelling"

    expect(parsed_response["suggested_queries"]).to eq([])
  end

  it "spell checking without typo" do
    build_sample_documents_on_content_indices(documents_per_index: 1)

    get "/search?q=milliband"

    expect(parsed_response["suggested_queries"]).to eq([])
  end

  it "returns docs from all indexes" do
    build_sample_documents_on_content_indices(documents_per_index: 1)

    get "/search?q=important"

    expect(result_links).to include "/government-1"
    expect(result_links).to include "/govuk-1"
  end

  it "sort by date ascending" do
    build_sample_documents_on_content_indices(documents_per_index: 2)

    get "/search?q=important&order=public_timestamp"

    expect(result_links.take(2)).to eq(["/government-1", "/government-2"])
  end

  it "sort by date descending" do
    build_sample_documents_on_content_indices(documents_per_index: 2)

    get "/search?q=important&order=-public_timestamp"

    # The government links have dates, so appear before all the other links.
    # The other documents have no dates, so appear in an undefined order
    expect(result_links.take(2)).to eq(["/government-2", "/government-1"])
  end

  it "sort by title ascending" do
    build_sample_documents_on_content_indices(documents_per_index: 1)

    get "/search?order=title"
    lowercase_titles = result_titles.map(&:downcase)

    expect(lowercase_titles).to eq(["sample government document 1", "sample govuk document 1"])
  end

  it "filter by field" do
    build_sample_documents_on_content_indices(documents_per_index: 1)

    get "/search?filter_mainstream_browse_pages=browse/page/1"

    expect(result_links.sort).to eq(["/government-1", "/govuk-1"])
  end

  it "reject by field" do
    build_sample_documents_on_content_indices(documents_per_index: 2)

    get "/search?reject_mainstream_browse_pages=browse/page/1"

    expect(result_links.sort).to eq(["/government-2", "/govuk-2"])
  end

  it "can filter for missing field" do
    build_sample_documents_on_content_indices(documents_per_index: 1)

    get "/search?filter_specialist_sectors=_MISSING"

    expect(result_links.sort).to eq(["/government-1", "/govuk-1"])
  end

  it "can filter for missing or specific value in field" do
    build_sample_documents_on_content_indices(documents_per_index: 1)

    get "/search?filter_specialist_sectors[]=_MISSING&filter_specialist_sectors[]=farming"

    expect(result_links.sort).to eq(["/government-1", "/govuk-1"])
  end

  it "can filter and reject" do
    build_sample_documents_on_content_indices(documents_per_index: 2)

    get "/search?reject_mainstream_browse_pages=1&filter_specialist_sectors[]=farming"

    expect(result_links.sort).to eq(["/government-2", "/govuk-2"])
  end

  describe "filter/reject when an attribute has multiple values" do
    before do
      commit_document(
        "government_test",
        "link" => "/one",
        "part_of_taxonomy_tree" => %w[a b c],
      )
      commit_document(
        "government_test",
        "link" => "/two",
        "part_of_taxonomy_tree" => %w[d e f],
      )
      commit_document(
        "government_test",
        "link" => "/three",
        "part_of_taxonomy_tree" => %w[b e],
      )
    end

    describe "filter_all" do
      it "filters all documents containing taxon b and e" do
        get "/search?filter_all_part_of_taxonomy_tree=b&filter_all_part_of_taxonomy_tree=e"
        expect(result_links.sort).to eq([
          "/three",
        ])
      end
    end

    describe "filter_any" do
      it "filters any document containing taxon c or f" do
        get "/search?filter_any_part_of_taxonomy_tree=c&filter_any_part_of_taxonomy_tree=f"
        expect(result_links.sort).to match_array([
          "/one", "/two"
        ])
      end
    end

    describe "reject_all" do
      it "rejects all documents containing taxon b and e" do
        get "/search?reject_all_part_of_taxonomy_tree=b&reject_all_part_of_taxonomy_tree=e"
        expect(result_links.sort).to match_array([
          "/one", "/two"
        ])
      end
    end

    describe "reject_any" do
      it "rejects any documents containing taxon c or f" do
        get "/search?reject_any_part_of_taxonomy_tree=c&reject_any_part_of_taxonomy_tree=f"
        expect(result_links.sort).to match_array([
          "/three",
        ])
      end
    end
  end

  describe "boolean filtering" do
    context "when boolean filters are not true or false" do
      it "returns an error" do
        get "/search?filter_is_withdrawn=blah"

        expect(last_response.status).to eq(422)
        expect(parsed_response).to eq({ "error" => "is_withdrawn requires a boolean (true or false)" })
      end
    end

    context "when an invalid filter is used" do
      it "returns an error" do
        get "/search?filter_has_some_very_incorrect_filter=false"

        expect(last_response.status).to eq(422)
        expect(parsed_response).to eq({ "error" => "\"has_some_very_incorrect_filter\" is not a valid filter field" })
      end
    end

    context "when a valid filter is used" do
      before do
        build_sample_documents_on_content_indices(documents_per_index: 2)
        commit_ministry_of_magic_document(has_official_document: true)
        commit_treatment_of_dragons_document(has_official_document: false)
      end

      it "can filter on boolean fields = true" do
        get "/search?filter_has_official_document=true"

        expect(result_links.sort).to eq(%w[/ministry-of-magic-site])
      end

      it "can filter on boolean fields = false" do
        get "/search?filter_has_official_document=false"

        expect(result_links.sort).to eq(%w[/dragon-guide])
      end
    end
  end

  it "only contains fields which are present" do
    build_sample_documents_on_content_indices(documents_per_index: 2)

    get "/search?q=important&order=public_timestamp"

    results = parsed_response["results"]
    expect(results[0].keys).not_to include("specialist_sectors")
    expect(results[1]["specialist_sectors"]).to eq([{ "slug" => "farming" }])
  end

  it "validates integer params" do
    get "/search?start=a"

    expect(last_response.status).to eq(422)
    expect(parsed_response).to eq({ "error" => "Invalid value \"a\" for parameter \"start\" (expected positive integer)" })
  end

  it "allows integer params leading zeros" do
    get "/search?start=09"

    expect(last_response).to be_ok
  end

  it "validates unknown params" do
    get "/search?foo&bar=1"

    expect(last_response.status).to eq(422)
    expect(parsed_response).to eq("error" => "Unexpected parameters: foo, bar")
  end

  it "debug explain returns explanations" do
    build_sample_documents_on_content_indices(documents_per_index: 1)

    get "/search?debug=explain"

    first_hit_explain = parsed_response["results"].first["_explanation"]
    expect(first_hit_explain).not_to be_nil
    expect(first_hit_explain.keys).to include("value")
    expect(first_hit_explain.keys).to include("description")
    expect(first_hit_explain.keys).to include("details")
  end

  it "can scope by elasticsearch type" do
    commit_document("govuk_test", cma_case_attributes, type: "cma_case")

    get "/search?filter_document_type=cma_case"

    expect(last_response).to be_ok
    expect(parsed_response.fetch("total")).to eq(1)
    expect(parsed_response.fetch("results").fetch(0)).to match(
      hash_including(
        "document_type" => "cma_case",
        "title" => cma_case_attributes.fetch("title"),
        "link" => cma_case_attributes.fetch("link"),
      ),
    )
  end

  it "can filter between dates" do
    commit_document("govuk_test", cma_case_attributes, type: "cma_case")

    get "/search?filter_document_type=cma_case&filter_opened_date=from:2014-03-31,to:2014-04-02"

    expect(last_response).to be_ok
    expect(parsed_response.fetch("total")).to eq(1)
    expect(parsed_response.fetch("results").fetch(0)).to match(
      hash_including(
        "title" => cma_case_attributes.fetch("title"),
        "link" => cma_case_attributes.fetch("link"),
      ),
    )
  end

  it "can filter between dates with reversed parameter order" do
    commit_document("govuk_test", cma_case_attributes, type: "cma_case")

    get "/search?filter_document_type=cma_case&filter_opened_date=to:2014-04-02,from:2014-03-31"

    expect(last_response).to be_ok
    expect(parsed_response.fetch("total")).to eq(1)
    expect(parsed_response.fetch("results").fetch(0)).to match(
      hash_including(
        "title" => cma_case_attributes.fetch("title"),
        "link" => cma_case_attributes.fetch("link"),
      ),
    )
  end

  it "can filter from date" do
    commit_filter_from_date_documents
    get "/search?filter_document_type=cma_case&filter_opened_date=from:2014-03-31"

    expect(last_response).to be_ok
    expect_response_includes_matching_date_and_datetime_results(parsed_response.fetch("results"))
  end

  it "can filter from time" do
    commit_filter_from_time_documents
    get "/search?filter_document_type=cma_case&filter_opened_date=from:2014-03-31 14:00:00"

    expect(last_response).to be_ok
    expect_response_includes_matching_date_and_datetime_results(parsed_response.fetch("results"))
  end

  it "can filter to date" do
    commit_filter_to_date_documents

    get "/search?filter_document_type=cma_case&filter_opened_date=to:2014-04-02"

    expect(last_response).to be_ok
    expect_response_includes_matching_date_and_datetime_results(parsed_response.fetch("results"))
  end

  it "can filter to time" do
    commit_filter_to_time_documents

    get "/search?filter_document_type=cma_case&filter_opened_date=to:2014-04-02 11:00:00"

    expect(last_response).to be_ok
    expect_response_includes_matching_date_and_datetime_results(parsed_response.fetch("results"))
  end

  it "can filter times in different time zones" do
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

    get "/search?filter_document_type=cma_case&filter_opened_date=from:2017-07-01 12:00,to:2017-07-01 23:30:00"

    expect(last_response).to be_ok
    expect(parsed_response.fetch("results")).to contain_exactly(
      hash_including("link" => "/cma-1"),
      hash_including("link" => "/cma-2"),
    )
  end

  it "cannot provide date filter key multiple times" do
    get "/search?filter_document_type=cma_case&filter_opened_date[]=from:2014-03-31&filter_opened_date[]=to:2014-04-02"

    expect(last_response.status).to eq(422)
    expect(
      parsed_response,
    ).to eq(
      { "error" => %{Too many values (2) for parameter "opened_date" (must occur at most once)} },
    )
  end

  it "cannot provide invalid dates for date filter" do
    get "/search?filter_document_type=cma_case&filter_opened_date=from:not-a-date"

    expect(last_response.status).to eq(422)
    expect(
      parsed_response,
    ).to eq(
      { "error" => %{Invalid "from" value "not-a-date" for parameter "opened_date" (expected ISO8601 date)} },
    )
  end

  it "expands organisations" do
    commit_treatment_of_dragons_document({ "organisations" => ["/ministry-of-magic"] })
    commit_ministry_of_magic_document({ "format" => "organisation" })

    get "/search.json?q=dragons"

    expect(first_result["organisations"]).to eq(
      [{ "slug" => "/ministry-of-magic",
         "link" => "/ministry-of-magic-site",
         "title" => "Ministry of Magic" }],
    )
  end

  it "also works with the /api prefix" do
    commit_treatment_of_dragons_document({ "organisations" => ["/ministry-of-magic"] })
    commit_ministry_of_magic_document({ "format" => "organisation" })

    get "/api/search.json?q=dragons"

    expect(first_result["organisations"]).to eq(
      [{ "slug" => "/ministry-of-magic",
         "link" => "/ministry-of-magic-site",
         "title" => "Ministry of Magic" }],
    )
  end

  it "expands organisations via content_id" do
    commit_treatment_of_dragons_document({ "organisation_content_ids" => %w[organisation-content-id] })
    commit_ministry_of_magic_document({ "content_id" => "organisation-content-id", "format" => "organisation" })

    get "/search.json?q=dragons"

    # Adds a new key with the expanded organisations
    expect_result_includes_ministry_of_magic_for_key(first_result, "expanded_organisations", "content_id" => "organisation-content-id")

    # Keeps the organisation content ids
    expect(
      first_result["organisation_content_ids"],
    ).to eq(
      %w[organisation-content-id],
    )
  end

  it "search for expanded organisations works" do
    commit_treatment_of_dragons_document({ "organisation_content_ids" => %w[organisation-content-id] })
    commit_ministry_of_magic_document({ "content_id" => "organisation-content-id", "format" => "organisation" })

    get "/search.json?q=dragons&fields[]=expanded_organisations"

    expect_result_includes_ministry_of_magic_for_key(first_result, "expanded_organisations", "content_id" => "organisation-content-id")
  end

  it "filter by organisation content_ids works" do
    commit_treatment_of_dragons_document({ "organisation_content_ids" => %w[organisation-content-id] })
    commit_ministry_of_magic_document({ "content_id" => "organisation-content-id", "format" => "organisation" })

    get "/search.json?filter_organisation_content_ids[]=organisation-content-id"

    expect_result_includes_ministry_of_magic_for_key(first_result, "expanded_organisations", "content_id" => "organisation-content-id")
  end

  it "will filter by topical_events slug" do
    topical_event_of_interest = "quiddich-world-cup-2018"

    # we DON'T want this document in our search results
    commit_document(
      "government_test",
      "title" => "Rules of Quiddich (2017)",
      "link" => "/quiddich-rules-2017",
      "format" => "detailed_guidance",
      "topical_events" => %w[quiddich-world-cup-2017],
    )

    # we DO want this document in our search results
    commit_document(
      "government_test",
      "title" => "Rules of Quiddich (2018)",
      "link" => "/quiddich-rules-2018",
      "format" => "detailed_guidance",
      "topical_events" => [topical_event_of_interest],
    )

    get "/search.json?filter_topical_events=#{topical_event_of_interest}"

    expect(first_result["topical_events"]).to be_truthy
    expect(first_result["topical_events"]).to eq([topical_event_of_interest])
    expect(parsed_response["results"].length).to eq 1
  end

  it "expands topics" do
    commit_treatment_of_dragons_document({ "topic_content_ids" => %w[topic-content-id] })
    commit_ministry_of_magic_document({ "index" => "govuk_test",
                                        "content_id" => "topic-content-id",
                                        "slug" => "topic-magic",
                                        "title" => "Magic topic",
                                        "link" => "/magic-topic-site",
                                        # TODO: we should rename this format to `topic` and update all apps
                                        "format" => "specialist_sector" })

    get "/search.json?q=dragons"

    # Adds a new key with the expanded topics
    expect_result_includes_ministry_of_magic_for_key(
      first_result,
      "expanded_topics",
      {
        "content_id" => "topic-content-id",
        "slug" => "topic-magic",
        "link" => "/magic-topic-site",
        "title" => "Magic topic",
      },
    )

    # Keeps the topic content ids
    expect(first_result["topic_content_ids"]).to eq(%w[topic-content-id])
  end

  it "filter by topic content_ids works" do
    commit_treatment_of_dragons_document({ "topic_content_ids" => %w[topic-content-id] })
    commit_ministry_of_magic_document({ "index" => "govuk_test",
                                        "content_id" => "topic-content-id",
                                        "slug" => "topic-magic",
                                        "title" => "Magic topic",
                                        "link" => "/magic-topic-site",
                                        # TODO: we should rename this format to `topic` and update all apps
                                        "format" => "specialist_sector" })

    get "/search.json?filter_topic_content_ids[]=topic-content-id"

    expect(first_result["topic_content_ids"]).to eq(%w[topic-content-id])
  end

  it "will not return withdrawn content" do
    commit_treatment_of_dragons_document({ "is_withdrawn" => true })
    get "/search?q=Advice on Treatment of Dragons"
    expect(parsed_response.fetch("total")).to eq(0)
  end

  it "will return withdrawn content with flag" do
    commit_treatment_of_dragons_document({ "is_withdrawn" => true })

    get "/search?q=Advice on Treatment of Dragons&debug=include_withdrawn&fields[]=is_withdrawn"
    expect(parsed_response.fetch("total")).to eq(1)
    expect(parsed_response.dig("results", 0, "is_withdrawn")).to be true
  end

  it "will return withdrawn content with flag with aggregations" do
    commit_treatment_of_dragons_document({ "is_withdrawn" => true })
    get "/search?q=Advice on Treatment of Dragons&debug=include_withdrawn&aggregate_mainstream_browse_pages=2"
    expect(parsed_response.fetch("total")).to eq(1)
  end

  it "will show the query" do
    get "/search?q=test&debug=show_query"

    expect(parsed_response.fetch("elasticsearch_query")).to be_truthy
  end

  it "will show the cluster" do
    get "/search?q=test"
    expect(parsed_response.fetch("es_cluster")).to eq(Clusters.default_cluster.key)

    Clusters.active.each do |cluster|
      get "/search?q=test&ab_tests=search_cluster_query:#{cluster.key}"
      expect(parsed_response.fetch("es_cluster")).to eq(cluster.key)
    end
  end

  it "can return the taxonomy" do
    commit_ministry_of_magic_document("taxons" => %w[eb2093ef-778c-4105-9f33-9aa03d14bc5c])

    get "/search?q=Ministry of Magict&fields[]=taxons"
    expect(parsed_response.fetch("total")).to eq(1)

    taxons = parsed_response.dig("results", 0, "taxons")
    expect(taxons).to eq(%w[eb2093ef-778c-4105-9f33-9aa03d14bc5c])
  end

  it "taxonomy can be filtered" do
    commit_ministry_of_magic_document("taxons" => %w[eb2093ef-778c-4105-9f33-9aa03d14bc5c])
    commit_treatment_of_dragons_document("taxons" => %w[some-other-taxon])

    get "/search?filter_taxons=eb2093ef-778c-4105-9f33-9aa03d14bc5c"

    expect(last_response).to be_ok
    expect(parsed_response.fetch("total")).to eq(1)
    expect_result_includes_ministry_of_magic_for_key(
      parsed_response,
      "results",
      {
        "_id" => "/ministry-of-magic-site",
        "document_type" => "edition",
        "elasticsearch_type" => "edition",
        "es_score" => nil,
        "index" => "government_test",
        "link" => "/ministry-of-magic-site",
      },
    )
  end

  it "can filter by part of taxonomy" do
    commit_ministry_of_magic_document(
      {
        "taxons" => %w[eb2093ef-778c-4105-9f33-9aa03d14bc5c],
        "part_of_taxonomy_tree" => %w[eb2093ef-778c-4105-9f33-9aa03d14bc5c aa2093ef-778c-4105-9f33-9aa03d14bc5c],
      },
    )
    get "/search?filter_part_of_taxonomy_tree=eb2093ef-778c-4105-9f33-9aa03d14bc5c"

    expect(last_response).to be_ok
    expect(parsed_response.fetch("total")).to eq(1)

    get "/search?filter_part_of_taxonomy_tree=aa2093ef-778c-4105-9f33-9aa03d14bc5c"

    expect(last_response).to be_ok
    expect(parsed_response.fetch("total")).to eq(1)
  end

  it "can filter by facet value" do
    commit_ministry_of_magic_document({ "facet_values" => %w[fe2fc3b5-a71b-4063-9605-12c3e6e179d6] })
    commit_treatment_of_dragons_document({ "facet_values" => %w[e602eb34-a870-46ff-8ba4-de36689fb028] })
    get "/search?filter_facet_values=fe2fc3b5-a71b-4063-9605-12c3e6e179d6"
    expect(last_response).to be_ok
    expect(parsed_response.fetch("total")).to eq(1)
    expect_result_includes_ministry_of_magic_for_key(
      parsed_response,
      "results",
      {
        "_id" => "/ministry-of-magic-site",
        "document_type" => "edition",
        "elasticsearch_type" => "edition",
        "es_score" => nil,
        "index" => "government_test",
        "link" => "/ministry-of-magic-site",
      },
    )
  end

  it "can filter by facet group" do
    commit_ministry_of_magic_document({ "facet_groups" => %w[fe2fc3b5-a71b-4063-9605-12c3e6e179d6] })
    commit_treatment_of_dragons_document({ "facet_groups" => %w[e602eb34-a870-46ff-8ba4-de36689fb028] })
    get "/search?filter_facet_groups=fe2fc3b5-a71b-4063-9605-12c3e6e179d6"
    expect(last_response).to be_ok
    expect(parsed_response.fetch("total")).to eq(1)
    expect_result_includes_ministry_of_magic_for_key(
      parsed_response,
      "results",
      {
        "_id" => "/ministry-of-magic-site",
        "document_type" => "edition",
        "elasticsearch_type" => "edition",
        "es_score" => nil,
        "index" => "government_test",
        "link" => "/ministry-of-magic-site",
      },
    )
  end

  it "can filter by roles" do
    commit_ministry_of_magic_document("roles" => %w[prime-minister])
    commit_treatment_of_dragons_document("roles" => %w[some-other-role])

    get "/search?filter_roles=prime-minister"

    expect(last_response).to be_ok
    expect(parsed_response.fetch("total")).to eq(1)

    expect_result_includes_ministry_of_magic_for_key(
      parsed_response,
      "results",
      {
        "_id" => "/ministry-of-magic-site",
        "document_type" => "edition",
        "elasticsearch_type" => "edition",
        "es_score" => nil,
        "index" => "government_test",
        "link" => "/ministry-of-magic-site",
      },
    )
  end

private

  def first_result
    @first_result ||= parsed_response["results"].first
  end

  def result_links
    @result_links ||= parsed_response["results"].map do |result|
      result["link"]
    end
  end

  def result_titles
    @result_titles ||= parsed_response["results"].map do |result|
      result["title"]
    end
  end
end
