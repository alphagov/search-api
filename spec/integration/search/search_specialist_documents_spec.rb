require "spec_helper"
require_relative "../../support/search_integration_spec_helper"

RSpec.configure do |c|
  c.include SearchIntegrationSpecHelper
end

RSpec.describe "SearchSpecialistDocumentsTest" do
  let(:index) { "specialist-finder_test" }

  it "returns success" do
    get "/specialist-documents-search?q=important"

    expect(last_response).to be_ok
  end

  it "spell checking with typo" do
    document_params = {
      "slug" => "/ministry-of-magic",
      "link" => "/ministry-of-magic-site",
      "title" => "Ministry of Magic",
    }
    commit_document("government_test", document_params)

    get "/specialist-documents-search?q=ministry of magick&suggest=spelling"

    expect(parsed_response["suggested_queries"]).to eq(["ministry of magic"])
  end

  it "highlights spelling suggestions" do
    document_params = {
      "slug" => "/ministry-of-magic",
      "link" => "/ministry-of-magic-site",
      "title" => "Ministry of Magic",
    }
    commit_document("government_test", document_params)

    get "/specialist-documents-search?q=ministry of magick&suggest=spelling_with_highlighting"

    expect(parsed_response["suggested_queries"]).to eq([{
      "text" => "ministry of magic",
      "highlighted" => "ministry of <mark>magic</mark>",
    }])
  end

  it "spell checking with blocklisted typo" do
    commit_document(
      index,
      {
        "title" => "Brexitt",
        "description" => "Brexitt",
        "link" => "/brexitt",
      },
    )

    get "/specialist-documents-search?q=brexit&suggest=spelling"

    expect(parsed_response["suggested_queries"]).to eq([])
  end

  it "spell checking without typo" do
    add_sample_documents(index, 1)

    get "/specialist-documents-search?q=milliband"

    expect(parsed_response["suggested_queries"]).to eq([])
  end

  it "sort by date ascending" do
    add_sample_documents(index, 2)

    get "/specialist-documents-search?q=important&order=public_timestamp"

    expect(result_links.take(2)).to eq(["/specialist-finder-1", "/specialist-finder-2"])
  end

  it "sort by date descending" do
    add_sample_documents(index, 2)

    get "/specialist-documents-search?q=important&order=-public_timestamp"

    # The government links have dates, so appear before all the other links.
    # The other documents have no dates, so appear in an undefined order
    expect(result_links.take(2)).to eq(["/specialist-finder-1", "/specialist-finder-2"])
  end

  it "sort by title ascending" do
    add_sample_documents(index, 1)

    get "/specialist-documents-search?order=title"
    lowercase_titles = result_titles.map(&:downcase)

    expect(lowercase_titles).to eq(["sample specialist-finder document 1"])
  end

  it "filter by field" do
    add_sample_documents(index, 1)

    get "/specialist-documents-search?filter_mainstream_browse_pages=browse/page/1"

    expect(result_links.sort).to eq(["/specialist-finder-1"])
  end

  it "reject by field" do
    add_sample_documents(index, 2)

    get "/specialist-documents-search?reject_mainstream_browse_pages=browse/page/1"

    expect(result_links.sort).to eq(["/specialist-finder-2"])
  end

  it "can filter for missing field" do
    add_sample_documents(index, 1)

    get "/specialist-documents-search?filter_manual=_MISSING"

    expect(result_links.sort).to eq(["/specialist-finder-1"])
  end

  it "can filter for missing or specific value in field" do
    add_sample_documents(index, 1)

    get "/specialist-documents-search?filter_document_type[]=_MISSING&filter_document_type[]=edition"

    expect(result_links.sort).to eq(["/specialist-finder-1"])
  end

  it "can filter and reject" do
    add_sample_documents(index, 2)

    get "/specialist-documents-search?reject_mainstream_browse_pages=1&filter_document_type[]=edition"

    expect(result_links.sort).to eq(["/specialist-finder-1", "/specialist-finder-2"])
  end

  describe "filter/reject when an attribute has multiple values" do
    before do
      commit_document(
        index,
        {
          "link" => "/one",
          "part_of_taxonomy_tree" => %w[a b c],
        },
      )
      commit_document(
        index,
        {
          "link" => "/two",
          "part_of_taxonomy_tree" => %w[d e f],
        },
      )
      commit_document(
        index,
        {
          "link" => "/three",
          "part_of_taxonomy_tree" => %w[b e],
        },
      )
    end

    describe "filter_all" do
      it "filters all documents containing taxon b and e" do
        get "/specialist-documents-search?filter_all_part_of_taxonomy_tree=b&filter_all_part_of_taxonomy_tree=e"
        expect(result_links.sort).to eq([
          "/three",
        ])
      end
    end

    describe "filter_any" do
      it "filters any document containing taxon c or f" do
        get "/specialist-documents-search?filter_any_part_of_taxonomy_tree=c&filter_any_part_of_taxonomy_tree=f"
        expect(result_links.sort).to match_array([
          "/one", "/two"
        ])
      end
    end

    describe "reject_all" do
      it "rejects all documents containing taxon b and e" do
        get "/specialist-documents-search?reject_all_part_of_taxonomy_tree=b&reject_all_part_of_taxonomy_tree=e"
        expect(result_links.sort).to match_array([
          "/one", "/two"
        ])
      end
    end

    describe "reject_any" do
      it "rejects any documents containing taxon c or f" do
        get "/specialist-documents-search?reject_any_part_of_taxonomy_tree=c&reject_any_part_of_taxonomy_tree=f"
        expect(result_links.sort).to match_array([
          "/three",
        ])
      end
    end
  end

  describe "boolean filtering" do
    context "when boolean filters are not true or false" do
      it "returns an error" do
        get "/specialist-documents-search?filter_is_withdrawn=blah"

        expect(last_response.status).to eq(422)
        expect(parsed_response).to eq({ "error" => "is_withdrawn requires a boolean (true or false)" })
      end
    end

    context "when an invalid filter is used" do
      it "returns an error" do
        get "/specialist-documents-search?filter_has_some_very_incorrect_filter=false"

        expect(last_response.status).to eq(422)
        expect(parsed_response).to eq({ "error" => "\"has_some_very_incorrect_filter\" is not a valid filter field" })
      end
    end

    context "when a valid filter is used" do
      before do
        add_sample_documents(index, 2)
        document_params = {
          "slug" => "/ministry-of-magic",
          "link" => "/ministry-of-magic-site",
          "title" => "Ministry of Magic",
          "has_official_document" => true,
        }
        commit_document("government_test", document_params)

        document_params = {
          "title" => "Advice on Treatment of Dragons",
          "link" => "/dragon-guide",
          "has_official_document" => false,
        }
        commit_document("government_test", document_params)
      end

      it "can filter on boolean fields = true" do
        get "/specialist-documents-search?filter_has_official_document=true"
        expect(result_links.sort).to eq(%w[/ministry-of-magic-site])
      end

      it "can filter on boolean fields = false" do
        get "/specialist-documents-search?filter_has_official_document=false"

        expect(result_links.sort).to eq(%w[/dragon-guide])
      end
    end
  end

  it "only contains fields which are present" do
    add_sample_documents(index, 2)

    get "/specialist-documents-search?q=important&order=public_timestamp"

    results = parsed_response["results"]
    expect(results[1]["title"]).to eq("Sample specialist-finder document 2")
  end

  it "validates integer params" do
    get "/specialist-documents-search?start=a"

    expect(last_response.status).to eq(422)
    expect(parsed_response).to eq({ "error" => "Invalid value \"a\" for parameter \"start\" (expected positive integer)" })
  end

  it "allows integer params leading zeros" do
    get "/specialist-documents-search?start=09"

    expect(last_response).to be_ok
  end

  it "validates unknown params" do
    get "/specialist-documents-search?foo&bar=1"

    expect(last_response.status).to eq(422)
    expect(parsed_response).to eq("error" => "Unexpected parameters: foo, bar")
  end

  it "debug explain returns explanations" do
    add_sample_documents(index, 1)

    get "/specialist-documents-search?debug=explain"

    first_hit_explain = parsed_response["results"].first["_explanation"]
    expect(first_hit_explain).not_to be_nil
    expect(first_hit_explain.keys).to include("value")
    expect(first_hit_explain.keys).to include("description")
    expect(first_hit_explain.keys).to include("details")
  end

  it "can scope by elasticsearch type" do
    commit_document(index, cma_case_attributes, type: "cma_case")

    get "/specialist-documents-search?filter_document_type=cma_case"

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
    commit_document(index, cma_case_attributes, type: "cma_case")

    get "/specialist-documents-search?filter_document_type=cma_case&filter_opened_date=from:2014-03-31,to:2014-04-02"

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
    commit_document(index, cma_case_attributes, type: "cma_case")

    get "/specialist-documents-search?filter_document_type=cma_case&filter_opened_date=to:2014-04-02,from:2014-03-31"

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
    commit_filter_from_date_documents(index)
    get "/specialist-documents-search?filter_document_type=cma_case&filter_opened_date=from:2014-03-31"

    expect(last_response).to be_ok
    expect_response_includes_matching_date_and_datetime_results(parsed_response.fetch("results"))
  end

  it "can filter from time" do
    commit_filter_from_time_documents(index)
    get "/specialist-documents-search?filter_document_type=cma_case&filter_opened_date=from:2014-03-31 14:00:00"

    expect(last_response).to be_ok
    expect_response_includes_matching_date_and_datetime_results(parsed_response.fetch("results"))
  end

  it "can filter to date" do
    commit_filter_to_date_documents(index)
    get "/specialist-documents-search?filter_document_type=cma_case&filter_opened_date=to:2014-04-02"

    expect(last_response).to be_ok
    expect_response_includes_matching_date_and_datetime_results(parsed_response.fetch("results"))
  end

  it "can filter to time" do
    commit_filter_to_time_documents(index)

    get "/specialist-documents-search?filter_document_type=cma_case&filter_opened_date=to:2014-04-02 11:00:00"

    expect(last_response).to be_ok
    expect_response_includes_matching_date_and_datetime_results(parsed_response.fetch("results"))
  end

  it "can filter times in different time zones" do
    commit_document(
      index,
      cma_case_attributes("opened_date" => "2017-07-01T11:20:00.000-03:00", "link" => "/cma-1"),
      type: "cma_case",
    )
    commit_document(
      index,
      cma_case_attributes("opened_date" => "2017-07-02T00:15:00.000+01:00", "link" => "/cma-2"),
      type: "cma_case",
    )

    get "/specialist-documents-search?filter_document_type=cma_case&filter_opened_date=from:2017-07-01 12:00,to:2017-07-01 23:30:00"

    expect(last_response).to be_ok
    expect(parsed_response.fetch("results")).to contain_exactly(
      hash_including("link" => "/cma-1"),
      hash_including("link" => "/cma-2"),
    )
  end

  it "cannot provide date filter key multiple times" do
    get "/specialist-documents-search?filter_document_type=cma_case&filter_opened_date[]=from:2014-03-31&filter_opened_date[]=to:2014-04-02"

    expect(last_response.status).to eq(422)
    expect(
      parsed_response,
    ).to eq(
      { "error" => %{Too many values (2) for parameter "opened_date" (must occur at most once)} },
    )
  end

  it "cannot provide invalid dates for date filter" do
    get "/specialist-documents-search?filter_document_type=cma_case&filter_opened_date=from:not-a-date"

    expect(last_response.status).to eq(422)
    expect(
      parsed_response,
    ).to eq(
      { "error" => %{Invalid "from" value "not-a-date" for parameter "opened_date" (expected ISO8601 date)} },
    )
  end

  it "expands organisations" do
    document_params = {
      "title" => "Advice on Treatment of Dragons",
      "link" => "/dragon-guide",
      "organisations" => ["/ministry-of-magic"],
    }
    commit_document("government_test", document_params)

    document_params = {
      "slug" => "/ministry-of-magic",
      "link" => "/ministry-of-magic-site",
      "title" => "Ministry of Magic",
      "format" => "organisation",
    }
    commit_document("government_test", document_params)

    get "/specialist-documents-search.json?q=dragons"

    expect(first_result["organisations"]).to eq(
      [{ "slug" => "/ministry-of-magic",
         "link" => "/ministry-of-magic-site",
         "title" => "Ministry of Magic" }],
    )
  end

  it "also works with the /api prefix" do
    document_params = {
      "slug" => "/ministry-of-magic",
      "link" => "/ministry-of-magic-site",
      "title" => "Ministry of Magic",
      "format" => "organisation",
    }
    commit_document("government_test", document_params)

    document_params = {
      "title" => "Advice on Treatment of Dragons",
      "link" => "/dragon-guide",
      "organisations" => ["/ministry-of-magic"],
    }
    commit_document("government_test", document_params)

    get "/api/specialist-documents-search.json?q=dragons"

    expect(first_result["organisations"]).to eq(
      [{ "slug" => "/ministry-of-magic",
         "link" => "/ministry-of-magic-site",
         "title" => "Ministry of Magic" }],
    )
  end

  it "expands organisations via content_id" do
    document_params = {
      "slug" => "/ministry-of-magic",
      "link" => "/ministry-of-magic-site",
      "title" => "Ministry of Magic",
      "content_id" => "organisation-content-id",
      "format" => "organisation",
    }
    commit_document("government_test", document_params)

    document_params = {
      "title" => "Advice on Treatment of Dragons",
      "link" => "/dragon-guide",
      "organisation_content_ids" => %w[organisation-content-id],
    }
    commit_document("government_test", document_params)

    get "/specialist-documents-search.json?q=dragons"

    # Adds a new key with the expanded organisations
    expect_result_includes_ministry_of_magic_for_key(first_result, "expanded_organisations", "content_id" => "organisation-content-id")

    # Keeps the organisation content ids
    expect(
      first_result["organisation_content_ids"],
    ).to eq(
      %w[organisation-content-id],
    )
  end

  it "will show the query" do
    get "/specialist-documents-search?q=test&debug=show_query"

    expect(parsed_response.fetch("elasticsearch_query")).to be_truthy
  end

  it "will show the cluster" do
    get "/specialist-documents-search?q=test"
    expect(parsed_response.fetch("es_cluster")).to eq(Clusters.default_cluster.key)

    Clusters.active.each do |cluster|
      get "/specialist-documents-search?q=test&ab_tests=search_cluster_query:#{cluster.key}"
      expect(parsed_response.fetch("es_cluster")).to eq(cluster.key)
    end
  end

  it "can return the taxonomy" do
    document_params = {
      "slug" => "/ministry-of-magic",
      "link" => "/ministry-of-magic-site",
      "title" => "Ministry of Magic",
      "taxons" => %w[eb2093ef-778c-4105-9f33-9aa03d14bc5c],
    }
    commit_document(index, document_params)

    get "/specialist-documents-search?q=Ministry of Magict&fields[]=taxons"
    expect(parsed_response.fetch("total")).to eq(1)

    taxons = parsed_response.dig("results", 0, "taxons")
    expect(taxons).to eq(%w[eb2093ef-778c-4105-9f33-9aa03d14bc5c])
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

  def es_score_by_link(link)
    parsed_response["results"].find { |result| result["link"] == link }["es_score"]
  end
end
