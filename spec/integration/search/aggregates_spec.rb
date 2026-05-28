require "spec_helper"

RSpec.describe "search queries" do
  let(:index_name) { SearchConfig.govuk_index_name }

  context "aggregation" do
    context "There are two mainstream browse pages" do
      before do
        commit_document(index_name, build(:document, :all,
                                          indexable_content: "important",
                                          mainstream_browse_pages: "browse/page/1",
                                          link: "/govuk-1"))
        commit_document(index_name, build(:document, :all,
                                          indexable_content: "important",
                                          mainstream_browse_pages: "browse/page/2",
                                          link: "/govuk-2"))
      end
      it "returns document count" do
        get "/search?q=important&aggregate_mainstream_browse_pages=2"

        expect(parsed_response["total"]).to eq(2)

        expect(parsed_response["aggregates"]).to eq(
          "mainstream_browse_pages" => {
            "options" => [
              { "value" => { "slug" => "browse/page/1" }, "documents" => 1 },
              { "value" => { "slug" => "browse/page/2" }, "documents" => 1 },
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
        get "/search?q=important&facet_mainstream_browse_pages=2"

        expect(parsed_response["total"]).to eq(2)

        expect(parsed_response["facets"]).to eq(
          "mainstream_browse_pages" => {
            "options" => [
              { "value" => { "slug" => "browse/page/1" }, "documents" => 1 },
              { "value" => { "slug" => "browse/page/2" }, "documents" => 1 },
            ],
            "documents_with_no_value" => 0,
            "total_options" => 2,
            "missing_options" => 0,
            "scope" => "exclude_field_filter",
          },
        )
        expect(parsed_response["aggregates"]).to be_nil
      end

      it "returns count with filter on field, excluding field filter scope" do
        get "/search?q=important&aggregate_mainstream_browse_pages=2"
        results_without_filter = parsed_response

        get "/search?q=important&aggregate_mainstream_browse_pages=2&filter_mainstream_browse_pages=browse/page/1"
        results_with_filter = parsed_response

        expect(results_without_filter["total"]).to eq(2)
        expect(results_with_filter["total"]).to eq(1)

        expect(results_with_filter["aggregates"]).to eq(results_without_filter["aggregates"])

        expect(results_without_filter["aggregates"]["mainstream_browse_pages"]["options"].size).to eq(2)
      end

      it "returns count when there are missing options" do
        get "/search?q=important&aggregate_mainstream_browse_pages=1"

        expect(parsed_response["total"]).to eq(2)
        expect(parsed_response["aggregates"]).to eq(
          "mainstream_browse_pages" => {
            "options" => [
              { "value" => { "slug" => "browse/page/1" }, "documents" => 1 },
            ],
            "documents_with_no_value" => 0,
            "total_options" => 2,
            "missing_options" => 1,
            "scope" => "exclude_field_filter",
          },
        )
      end

      it "returns count when filtering on a field within an all filters scope" do
        get "/search?q=important&aggregate_mainstream_browse_pages=2,scope:all_filters&filter_mainstream_browse_pages=browse/page/1"

        expect(parsed_response["total"]).to eq(1)
        expect(parsed_response["aggregates"]).to eq(
          "mainstream_browse_pages" => {
            "options" => [
              { "value" => { "slug" => "browse/page/1" }, "documents" => 1 },
            ],
            "documents_with_no_value" => 0,
            "total_options" => 1,
            "missing_options" => 0,
            "scope" => "all_filters",
          },
        )
      end

      it "returns examples" do
        get "/search?q=important&aggregate_mainstream_browse_pages=1,examples:5,example_scope:global,example_fields:link:title:mainstream_browse_pages"

        expect(
          parsed_response["aggregates"]["mainstream_browse_pages"]["options"]
            .first["value"]["example_info"]["examples"]
            .map { |h| h["link"] }
            .sort,
        ).to eq(["/govuk-1"])
      end
    end
  end

  it "returns count with filter on a different field" do
    commit_document(index_name, build(:document, :all, organisations: %w[org1], mainstream_browse_pages: ["browse/page/1"]))
    commit_document(index_name, build(:document, :all, organisations: %w[org1], mainstream_browse_pages: ["browse/page/2"]))
    commit_document(index_name, build(:document, :all, organisations: %w[org2], mainstream_browse_pages: ["browse/page/1"]))
    commit_document(index_name, build(:document, :all, organisations: %w[org2], mainstream_browse_pages: ["browse/page/2"]))

    get "/search?aggregate_mainstream_browse_pages=2&filter_organisations=org2"
    expect(parsed_response["total"]).to eq(2)

    expect(parsed_response["aggregates"]["mainstream_browse_pages"]["options"]).to eq([
      { "value" => { "slug" => "browse/page/1" }, "documents" => 1 },
      { "value" => { "slug" => "browse/page/2" }, "documents" => 1 },
    ])
  end

  it "can be searched by every aggregate for research for development outputs" do
    research_for_development_output_attributes = {
      title: "Somewhat Unique Research For Development Output",
      link: "/reearch-for-development-outputs/somewhat-unique-research-for-development-output",
      country: %w[TZ AL],
      review_status: "peer_reviewed",
      first_published_at: "2014-04-02",
      format: "research_for_development_output",
    }

    commit_document(index_name, build(:document, research_for_development_output_attributes))

    aggregate_queries = %w(
      filter_review_status[]=peer_reviewed
      filter_country[]=TZ&filter_country[]=AL
    )

    aggregate_queries.each do |filter_query|
      get "/search?filter_format=research_for_development_output&#{filter_query}"

      expect(last_response).to be_ok
      expect(parsed_response["total"]).to eq(1), "Failure to search by #{filter_query}"
      expect(parsed_response["results"][0]).to include(
        "format" => "research_for_development_output",
        "title" => research_for_development_output_attributes[:title],
        "link" => research_for_development_output_attributes[:link],
      )
    end
  end
end
