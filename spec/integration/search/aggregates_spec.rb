require "spec_helper"

RSpec.describe "search queries" do
  context "aggregation" do
    it "returns document count" do
      build_sample_documents_on_content_indices(documents_per_index: 2)

      get "/search?q=important&aggregate_mainstream_browse_pages=2"

      expect(parsed_response["total"]).to eq(4)

      expect(parsed_response["aggregates"]).to eq(
        "mainstream_browse_pages" => {
          "options" => [
            { "value" => { "slug" => "browse/page/1" }, "documents" => 2 },
            { "value" => { "slug" => "browse/page/2" }, "documents" => 2 },
          ],
          "documents_with_no_value" => 0,
          "total_options" => 2,
          "missing_options" => 0,
          "scope" => "exclude_field_filter",
        },
      )
    end

    # we changed facet -> aggregate but still support both
    # the result set should match the naming used in the request
    it "returns results in field that reflects the name used in query" do
      build_sample_documents_on_content_indices(documents_per_index: 2)

      get "/search?q=important&facet_mainstream_browse_pages=2"

      expect(parsed_response["total"]).to eq(4)

      expect(parsed_response["facets"]).to eq(
        "mainstream_browse_pages" => {
          "options" => [
            { "value" => { "slug" => "browse/page/1" }, "documents" => 2 },
            { "value" => { "slug" => "browse/page/2" }, "documents" => 2 },
          ],
          "documents_with_no_value" => 0,
          "total_options" => 2,
          "missing_options" => 0,
          "scope" => "exclude_field_filter",
        },
      )
      expect(parsed_response["aggregates"]).to be_nil
    end
  end

  context "filtering" do
    it "returns count with filter on field, excluding field filter scope" do
      build_sample_documents_on_content_indices(documents_per_index: 2)

      get "/search?q=important&aggregate_mainstream_browse_pages=2"
      results_without_filter = parsed_response

      get "/search?q=important&aggregate_mainstream_browse_pages=2&filter_mainstream_browse_pages=browse/page/1"
      results_with_filter = parsed_response

      expect(results_without_filter["total"]).to eq(4)
      expect(results_with_filter["total"]).to eq(2)

      expect(results_with_filter["aggregates"]).to eq(results_without_filter["aggregates"])

      expect(results_without_filter["aggregates"]["mainstream_browse_pages"]["options"].size).to eq(2)
    end

    it "returns count with filter on a different field" do
      insert_document("govuk_test", organisations: ["org1"], mainstream_browse_pages: ["browse/page/1"], format: "answer")
      insert_document("govuk_test", organisations: ["org1"], mainstream_browse_pages: ["browse/page/2"], format: "answer")
      insert_document("govuk_test", organisations: ["org2"], mainstream_browse_pages: ["browse/page/1"], format: "answer")
      insert_document("govuk_test", organisations: ["org2"], mainstream_browse_pages: ["browse/page/2"], format: "answer")
      commit_index("govuk_test")

      get "/search?aggregate_mainstream_browse_pages=2&filter_organisations=org2"
      expect(parsed_response["total"]).to eq(2)

      expect(parsed_response["aggregates"]["mainstream_browse_pages"]["options"]).to eq([
        { "value" => { "slug" => "browse/page/1" }, "documents" => 1 },
        { "value" => { "slug" => "browse/page/2" }, "documents" => 1 }
      ])
    end
  end

  context "migrated formats" do
    it "does not include duplicate documents in govuk index within the count" do
      commit_document("govuk_test", { organisations: ["org1"] })
      commit_document("government_test", { organisations: ["org1"] })

      get "/search?aggregate_organisations=10"
      expect(parsed_response["total"]).to eq(1)

      expect(parsed_response["aggregates"]["organisations"]["options"]).to eq([
        { "value" => { "slug" => "org1" }, "documents" => 1 }
      ])
    end

    it "returns examples before migration" do
      allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return({})

      add_sample_documents("government_test", 2)
      add_sample_documents("govuk_test", 2)

      get "/search?q=important&aggregate_mainstream_browse_pages=1,examples:5,example_scope:global,example_fields:link:title:mainstream_browse_pages"

      options = parsed_response["aggregates"]["mainstream_browse_pages"]["options"]
      actual_results = options.first["value"]["example_info"]["examples"].map { |h| h["link"] }.sort

      expect(actual_results).to eq(%w(/government-1))
    end

    it "returns examples after migration" do
      allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return("answer" => :all)

      add_sample_documents("government_test", 2, override: { "format" => "answer" })
      add_sample_documents("govuk_test", 2)

      get "/search?q=important&aggregate_mainstream_browse_pages=1,examples:5,example_scope:global,example_fields:link:title:mainstream_browse_pages"

      options = parsed_response["aggregates"]["mainstream_browse_pages"]["options"]
      actual_results = options.first["value"]["example_info"]["examples"].map { |h| h["link"] }.sort

      expect(actual_results).to eq(%w(/govuk-1))
    end

    it "returns examples before migration within query scope" do
      allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return({})

      add_sample_documents("government_test", 2, override: { "format" => "answer" })
      add_sample_documents("govuk_test", 2)

      get "/search?q=important&aggregate_mainstream_browse_pages=1,examples:5,example_scope:query,example_fields:link:title:mainstream_browse_pages"

      options = parsed_response["aggregates"]["mainstream_browse_pages"]["options"]
      actual_results = options.first["value"]["example_info"]["examples"].map { |h| h["link"] }.sort

      expect(actual_results).to eq(%w(/government-1))
    end

    it "returns examples after migration within query scope" do
      allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return("answer" => :all)

      add_sample_documents("government_test", 2, override: { "format" => "answer" })
      add_sample_documents("govuk_test", 2)

      get "/search?q=important&aggregate_mainstream_browse_pages=1,examples:5,example_scope:query,example_fields:link:title:mainstream_browse_pages"

      options = parsed_response["aggregates"]["mainstream_browse_pages"]["options"]
      actual_results = options.first["value"]["example_info"]["examples"].map { |h| h["link"] }.sort

      expect(actual_results).to eq(%w(/govuk-1))
    end
  end

  it "returns count when there are missing options" do
    build_sample_documents_on_content_indices(documents_per_index: 2)

    get "/search?q=important&aggregate_mainstream_browse_pages=1"

    expect(parsed_response["total"]).to eq(4)
    expect(parsed_response["aggregates"]).to eq(
      "mainstream_browse_pages" => {
        "options" => [
          { "value" => { "slug" => "browse/page/1" }, "documents" => 2 },
        ],
        "documents_with_no_value" => 0,
        "total_options" => 2,
        "missing_options" => 1,
        "scope" => "exclude_field_filter",
      },
    )
  end

  it "returns count when filtering on a field within an all filters scope" do
    build_sample_documents_on_content_indices(documents_per_index: 2)

    get "/search?q=important&aggregate_mainstream_browse_pages=2,scope:all_filters&filter_mainstream_browse_pages=browse/page/1"

    expect(parsed_response["total"]).to eq(2)
    expect(parsed_response["aggregates"]).to eq(
      "mainstream_browse_pages" => {
        "options" => [
          { "value" => { "slug" => "browse/page/1" }, "documents" => 2 },
        ],
        "documents_with_no_value" => 0,
        "total_options" => 1,
        "missing_options" => 0,
        "scope" => "all_filters",
      },
    )
  end

  it "returns examples" do
    build_sample_documents_on_content_indices(documents_per_index: 2)

    get "/search?q=important&aggregate_mainstream_browse_pages=1,examples:5,example_scope:global,example_fields:link:title:mainstream_browse_pages"

    expect(
      parsed_response["aggregates"]["mainstream_browse_pages"]["options"]
        .first["value"]["example_info"]["examples"]
        .map { |h| h["link"] }
        .sort,
    ).to eq(["/government-1", "/govuk-1"])
  end

  it "can be searched by every aggregate for dfid" do
    dfid_research_output_attributes = {
      "title" => "Somewhat Unique DFID Research Output",
      "link" => "/dfid-research-outputs/somewhat-unique-dfid-research-output",
      "indexable_content" => "Use of calcrete in gender roles in Tanzania",
      "country" => %w(TZ AL),
      "dfid_review_status" => "peer_reviewed",
      "first_published_at" => "2014-04-02",
      "format" => "dfid_research_output",
    }

    commit_document("govuk_test", dfid_research_output_attributes, type: "dfid_research_output")

    aggregate_queries = %w(
      filter_dfid_review_status[]=peer_reviewed
      filter_country[]=TZ&filter_country[]=AL
    )

    aggregate_queries.each do |filter_query|
      get "/search?filter_document_type=dfid_research_output&#{filter_query}"

      expect(last_response).to be_ok
      expect(parsed_response["total"]).to eq(1), "Failure to search by #{filter_query}"
      expect(parsed_response["results"][0]).to include(
        "document_type" => "dfid_research_output",
        "title" => dfid_research_output_attributes["title"],
        "link" => dfid_research_output_attributes["link"],
      )
    end
  end
end
