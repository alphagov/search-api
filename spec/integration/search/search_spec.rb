require "spec_helper"

RSpec.describe "SearchTest" do
  let(:index_name) { SearchConfig.govuk_index_name }
  it_behaves_like "json-only endpoint", "/search", "?q=important"
  it_behaves_like "json-only endpoint", "/api/search", "?q=important"

  it "returns success" do
    get "/search?q=important"

    expect(last_response).to be_ok
  end

  it "spell checking with typo" do
    commit_document(index_name, build(:document, title: "Ministry of Magic"))
    get "/search?q=ministry of magick&suggest=spelling"

    expect(parsed_response["suggested_queries"]).to eq(["ministry of magic"])
  end

  it "highlights spelling suggestions" do
    commit_document(index_name, build(:document, title: "Ministry of Magic"))

    get "/search?q=ministry of magick&suggest=spelling_with_highlighting"

    expect(parsed_response["suggested_queries"]).to eq([{
      "text" => "ministry of magic",
      "highlighted" => "ministry of <mark>magic</mark>",
    }])
  end

  it "spell checking with blocklisted typo" do
    commit_document(index_name, build(:document, title: "Brexitt"))

    get "/search?q=brexit&suggest=spelling"

    expect(parsed_response["suggested_queries"]).to eq([])
  end

  it "spell checking without typo" do
    commit_document(index_name, build(:document, title: "Magic"))
    get "/search?q=london&suggest=spelling"

    expect(parsed_response["suggested_queries"]).to eq([])
  end

  describe "sorting" do
    before :each do
      commit_document(index_name, build(:document, link: "/one", title: "aa", public_timestamp: Time.now.utc.iso8601))
      commit_document(index_name, build(:document, link: "/two", title: "zz", public_timestamp: 1.week.from_now.utc.iso8601))
    end
    it "sort by date ascending" do
      get "/search?order=public_timestamp"

      expect(result_links.take(2)).to eq(["/one", "/two"])
    end

    it "sort by date descending" do
      get "/search?order=-public_timestamp"

      expect(result_links.take(2)).to eq(["/two", "/one"])
    end

    it "sort by title ascending" do
      get "/search?order=title"
      expect(result_titles).to eq(%w[aa zz])
    end

    it "sort by title descending" do
      get "/search?order=-title"
      expect(result_titles).to eq(%w[zz aa])
    end
  end

  describe "filtering" do
    before :each do
      commit_document(index_name, build(:document,
                                        link: "/one",
                                        mainstream_browse_pages: "browse/page/1"))
      commit_document(index_name, build(:document,
                                        link: "/two",
                                        mainstream_browse_pages: "browse/page/2"))
      commit_document(index_name, build(:document,
                                        link: "/missing"))
    end
    it "filter by field" do
      get "/search?filter_mainstream_browse_pages=browse/page/1"

      expect(result_links).to eq(["/one"])
    end

    it "reject by field" do
      get "/search?reject_mainstream_browse_pages=browse/page/1"

      expect(result_links).to match_array(["/two", "/missing"])
    end

    it "can filter for missing field" do
      get "/search?filter_mainstream_browse_pages=_MISSING"

      expect(result_links.sort).to eq(["/missing"])
    end

    it "can filter for missing or specific value in field" do
      get "/search?filter_mainstream_browse_pages[]=_MISSING&filter_mainstream_browse_pages[]=browse/page/1"

      expect(result_links.sort).to match_array(["/one", "/missing"])
    end

    it "can filter and reject" do
      get "/search?filter_mainstream_browse_pages[]=browse/page/2"
      expect(result_links.sort).to eq(["/two"])

      get "/search?reject_link=/two&filter_mainstream_browse_pages[]=browse/page/2"
      expect(result_links).to be_empty
    end
  end

  describe "filter/reject when an attribute has multiple values" do
    before do
      commit_document(index_name, build(:document, "part_of_taxonomy_tree" => %w[a b c], "link" => "/one"))
      commit_document(index_name, build(:document, "part_of_taxonomy_tree" => %w[d e f], "link" => "/two"))
      commit_document(index_name, build(:document, "part_of_taxonomy_tree" => %w[b e], "link" => "/three"))
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
        commit_document(index_name, build(:document, has_official_document: true, "link" => "/official"))
        commit_document(index_name, build(:document, has_official_document: false, "link" => "/not_official"))
      end

      it "can filter on boolean fields = true" do
        get "/search?filter_has_official_document=true"

        expect(result_links.sort).to eq(%w[/official])
      end

      it "can filter on boolean fields = false" do
        get "/search?filter_has_official_document=false"

        expect(result_links.sort).to eq(%w[/not_official])
      end
    end
  end

  it "only contains fields which are present" do
    commit_document(index_name, build(:document, "link" => "/early", "topical_events" => %w[a_topical_event]))
    commit_document(index_name, build(:document, "link" => "/late"))

    get "/search?order=public_timestamp"

    results = parsed_response["results"]
    expect(results[1].keys).not_to include("topical_events")
    expect(results[0]["topical_events"]).to eq(%w[a_topical_event])
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
    commit_document(index_name, build(:document, :all))

    get "/search?debug=explain"

    first_hit_explain = parsed_response["results"].first["_explanation"]
    expect(first_hit_explain).not_to be_nil
    expect(first_hit_explain.keys).to include("value")
    expect(first_hit_explain.keys).to include("description")
    expect(first_hit_explain.keys).to include("details")
  end

  it "can scope by elasticsearch type" do
    commit_document(index_name, build(:document, :cma_case, title: "cma title", link: "/cma-cases"))

    get "/search?filter_document_type=cma_case"

    expect(last_response).to be_ok
    expect(parsed_response.fetch("total")).to eq(1)
    expect(parsed_response.fetch("results").fetch(0)).to match(
      hash_including(
        "document_type" => "cma_case",
        "title" => "cma title",
        "link" => "/cma-cases",
      ),
    )
  end

  describe "filter dates" do
    let(:january) { Time.new(2000, 1, 1).utc.strftime("%Y-%m-%dT%H:%M:%S") }
    let(:february) { Time.new(2000, 2, 1, 13, 0, 0).utc.strftime("%Y-%m-%dT%H:%M:%S") }
    let(:march) { Time.new(2000, 3, 1).utc.strftime("%Y-%m-%dT%H:%M:%S") }

    before do
      commit_document(index_name, build(:document, link: "/february", opened_date: february))
      commit_document(index_name, build(:document, link: "/january", opened_date: january))
      commit_document(index_name, build(:document, link: "/march", opened_date: march))
    end

    it "can filter between dates" do
      get "/search?filter_opened_date=from:2000-01-20,to:2000-02-20"

      expect(last_response).to be_ok
      expect(result_links).to eq(["/february"])
    end

    it "can filter between dates with reversed parameter order" do
      get "/search?filter_opened_date=to:2000-02-20,from:2000-01-20"
      expect(last_response).to be_ok
      expect(result_links).to eq(["/february"])
    end

    it "can filter from date" do
      get "/search?filter_opened_date=from:2000-01-20"

      expect(last_response).to be_ok
      expect(result_links).to match_array(["/february", "/march"])
    end

    it "can filter from time" do
      get "/search?filter_opened_date=from:2000-02-1 12:00:00"
      expect(result_links).to include("/february")

      get "/search?filter_opened_date=from:2000-02-1 14:00:00"
      expect(result_links).to_not include("/february")
    end

    it "can filter to date" do
      get "/search?filter_opened_date=to:2000-02-20"

      expect(result_links).to match_array(["/january", "/february"])
    end

    it "can filter to time" do
      get "/search?filter_opened_date=to:2000-02-20 12:00:00"

      get "/search?filter_opened_date=to:2000-02-1 12:00:00"
      expect(result_links).not_to include("/february")

      get "/search?filter_opened_date=to:2000-02-1 14:00:00"
      expect(result_links).to include("/february")
    end
  end

  it "can filter times in different time zones" do
    january_time = "2017-07-01T11:20:00.000-03:00"
    february_time = "2017-07-02T01:15:00.000+01:00"

    commit_document(index_name, build(:document, link: "/february", opened_date: february_time))
    commit_document(index_name, build(:document, link: "/january", opened_date: january_time))

    get "/search?filter_opened_date=from:2017-07-01 12:00,to:2017-07-01 23:30:00"

    expect(last_response).to be_ok
    expect(parsed_response.fetch("results")).to contain_exactly(hash_including("link" => "/january"))
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
    commit_document(index_name, build(:document, indexable_content: "important", organisations: ["/my_organisation"]))
    commit_document(index_name, build(:document, format: "organisation", title: "my title", slug: "/my_organisation", link: "/my_link"))

    get "/search.json?q=important"

    expect(first_result["organisations"].first)
      .to include({ "slug" => "/my_organisation",
                    "link" => "/my_link",
                    "title" => "my title" })
  end

  it "also works with the /api prefix" do
    commit_document(index_name, build(:document, indexable_content: "important", organisations: ["/my_organisation"]))
    commit_document(index_name, build(:document, format: "organisation", title: "my title", slug: "/my_organisation", link: "/my_link"))

    get "/api/search.json?q=important"

    expect(first_result["organisations"].first)
      .to include({ "slug" => "/my_organisation",
                    "link" => "/my_link",
                    "title" => "my title" })
  end

  it "expands organisations via content_id" do
    commit_document(index_name, build(:document, format: "organisation",
                                                 content_id: "organisation-content-id",
                                                 title: "my title",
                                                 slug: "/my_organisation",
                                                 link: "/my_link"))
    commit_document(index_name, build(:document, indexable_content: "important",
                                                 organisation_content_ids: %w[organisation-content-id]))

    get "/search.json?q=important&fields[]=expanded_organisations"

    expect(first_result["expanded_organisations"].first)
      .to include({ "slug" => "/my_organisation",
                    "link" => "/my_link",
                    "title" => "my title" })
  end

  it "search for expanded organisations works" do
    commit_document(index_name, build(:document, format: "organisation",
                                                 content_id: "organisation-content-id",
                                                 title: "my title",
                                                 slug: "/my_organisation",
                                                 link: "/my_link"))
    commit_document(index_name, build(:document, indexable_content: "important",
                                                 organisation_content_ids: %w[organisation-content-id]))

    get "/search.json?filter_organisation_content_ids[]=organisation-content-id"

    expect(first_result["expanded_organisations"].first)
      .to include({ "slug" => "/my_organisation",
                    "link" => "/my_link",
                    "title" => "my title" })
  end

  it "will filter by topical_events slug" do
    commit_document(index_name, build(:document, format: "detailed_guide", "topical_events" => %w[remove_topical_event]))
    commit_document(index_name, build(:document, format: "detailed_guide", "topical_events" => %w[keep_topical_event]))

    get "/search.json?filter_topical_events=keep_topical_event"

    expect(first_result["topical_events"]).to eq(%w[keep_topical_event])
    expect(parsed_response["results"].length).to eq 1
  end

  it "will not return withdrawn content" do
    commit_document(index_name, build(:document, :all, is_withdrawn: true))

    get "/search"

    expect(result_links).to be_empty
  end

  it "will return withdrawn content with flag" do
    commit_document(index_name, build(:document, :all, link: "/my_link", is_withdrawn: true))

    get "/search?debug=include_withdrawn&fields[]=is_withdrawn,link"

    expect(result_links).to eq(["/my_link"])
    expect(parsed_response.dig("results", 0, "is_withdrawn")).to be true
  end

  it "will return withdrawn content with flag with aggregations" do
    commit_document(index_name, build(:document, :all, is_withdrawn: true, mainstream_browse_pages: ["/browse_pages"]))

    get "/search?&debug=include_withdrawn&aggregate_mainstream_browse_pages=2"

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
    commit_document(index_name, build(:document, :all, taxons: %w[eb2093ef-778c-4105-9f33-9aa03d14bc5c]))

    get "/search?fields[]=taxons"
    expect(parsed_response.fetch("total")).to eq(1)

    taxons = parsed_response.dig("results", 0, "taxons")
    expect(taxons).to eq(%w[eb2093ef-778c-4105-9f33-9aa03d14bc5c])
  end

  it "taxonomy can be filtered" do
    commit_document(index_name, build(:document, :all, link: "/my_link", taxons: %w[eb2093ef-778c-4105-9f33-9aa03d14bc5c]))
    commit_document(index_name, build(:document, :all, link: "/other_link", taxons: %w[some-other-taxon]))

    get "/search?filter_taxons=eb2093ef-778c-4105-9f33-9aa03d14bc5c"

    expect(result_links).to eq(["/my_link"])
  end

  it "can filter by part of taxonomy" do
    commit_document(index_name,
                    build(:document, :all, link: "/my_link",
                                           taxons: %w[eb2093ef-778c-4105-9f33-9aa03d14bc5c],
                                           part_of_taxonomy_tree: %w[eb2093ef-778c-4105-9f33-9aa03d14bc5c aa2093ef-778c-4105-9f33-9aa03d14bc5c]))

    get "/search?filter_part_of_taxonomy_tree=eb2093ef-778c-4105-9f33-9aa03d14bc5c"
    expect(result_links).to eq(["/my_link"])

    get "/search?filter_part_of_taxonomy_tree=aa2093ef-778c-4105-9f33-9aa03d14bc5c"
    expect(result_links).to eq(["/my_link"])
  end

  it "can filter by roles" do
    commit_document(index_name, build(:document, :all, link: "/my_link", roles: %w[prime-minister]))
    commit_document(index_name, build(:document, :all, link: "/other_link", roles: %w[some-other-role]))

    get "/search?filter_roles=prime-minister"

    expect(result_links).to eq(["/my_link"])
  end

  it "boosts custom fields" do
    less_relevant_licence = {
      "title" => "Less relevant licence",
      "link" => "/find-licences/less-relevant-licence",
      "indexable_content" => "Some body text that includes information",
      "format" => "licence_transaction",
      "document_type" => "licence_transaction",
    }

    more_relevant_licence = {
      "title" => "More relevant licence",
      "link" => "/find-licences/more-relevant-licence",
      "indexable_content" => "A more relevant licence",
      "format" => "licence_transaction",
      "document_type" => "licence_transaction",
      "licence_transaction_industry" => %w[information-and-data another-industry],
    }
    commit_document(index_name, build(:document, less_relevant_licence))
    commit_document(index_name, build(:document, more_relevant_licence))

    get "/search?q=information&boost_fields=licence_transaction_industry"

    higher_es_score = es_score_by_link("/find-licences/more-relevant-licence")
    lower_es_score = es_score_by_link("/find-licences/less-relevant-licence")

    expect(higher_es_score).to be > lower_es_score
  end

private

  def first_result
    parsed_response["results"].first
  end

  def result_links
    parsed_response["results"].map do |result|
      result["link"]
    end
  end

  def result_titles
    parsed_response["results"].map do |result|
      result["title"]
    end
  end

  def es_score_by_link(link)
    parsed_response["results"].find { |result| result["link"] == link }["es_score"]
  end
end
