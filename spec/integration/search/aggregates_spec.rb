require 'spec_helper'

RSpec.describe 'search queries' do
  context 'with aggregates' do
    it "returns document count" do
      populate_content_indexes(section_count: 2)

      get "/search?q=important&aggregate_mainstream_browse_pages=2"

      expect(parsed_response["total"]).to eq(4)

      aggregate = parsed_response["aggregates"]

      expect(
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
      ).to eq(aggregate)
    end

    # we changed facet -> aggregate but still support both
    # the result set should match the naming used in the request
    it "returns results in field that reflects the name used in query" do
      populate_content_indexes(section_count: 2)

      get "/search?q=important&facet_mainstream_browse_pages=2"

      expect(parsed_response["total"]).to eq(4)

      facets = parsed_response["facets"]

      expect(
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
      ).to eq(facets)
      expect(parsed_response['aggregates']).to be_nil
    end
  end

  # TODO: The `mainstream_browse_pages` fields are populated with a number, 1
  # or 2. This should be made more explicit.
  it "returns count with filter on field, excluding field filter scope" do
    populate_content_indexes(section_count: 2)

    get "/search?q=important&aggregate_mainstream_browse_pages=2"

    expect(parsed_response["total"]).to eq(4)
    aggregates_without_filter = parsed_response["aggregates"]

    get "/search?q=important&aggregate_mainstream_browse_pages=2&filter_mainstream_browse_pages=browse/page/1"
    expect(parsed_response["total"]).to eq(2)

    aggregates_with_filter = parsed_response["aggregates"]

    expect(aggregates_with_filter).to eq(aggregates_without_filter)
    expect(aggregates_without_filter["mainstream_browse_pages"]["options"].size).to eq(2)
  end

  it "returns count with filter on a different field" do
    insert_document('mainstream_test', { organisations: ['org1'], mainstream_browse_pages: ["browse/page/1"] })
    insert_document('mainstream_test', { organisations: ['org1'], mainstream_browse_pages: ["browse/page/2"] })
    insert_document('mainstream_test', { organisations: ['org2'], mainstream_browse_pages: ["browse/page/1"] })
    insert_document('mainstream_test', { organisations: ['org2'], mainstream_browse_pages: ["browse/page/2"] })
    commit_index

    get "/search?aggregate_mainstream_browse_pages=2&filter_organisations=org2"
    expect(parsed_response["total"]).to eq(2)

    expect(parsed_response["aggregates"]["mainstream_browse_pages"]["options"]).to eq([
      { "value" => { "slug" => "browse/page/1" }, "documents" => 1 },
      { "value" => { "slug" => "browse/page/2" }, "documents" => 1 }
    ])
  end

  it "does not include duplicate documents in govuk_index within the count" do
    commit_document('govuk_test', { organisations: ['org1'] })
    commit_document('mainstream_test', { organisations: ['org1'] })

    get "/search?aggregate_organisations=10"
    expect(parsed_response["total"]).to eq(1)

    expect(parsed_response["aggregates"]["organisations"]["options"]).to eq([
      { "value" => { "slug" => "org1" }, "documents" => 1 }
    ])
  end

  it "returns count when there are missing_options" do
    populate_content_indexes(section_count: 2)

    get "/search?q=important&aggregate_mainstream_browse_pages=1"

    expect(parsed_response["total"]).to eq(4)
    aggregates = parsed_response["aggregates"]
    expect(
      "mainstream_browse_pages" => {
        "options" => [
          { "value" => { "slug" => "browse/page/1" }, "documents" => 2 },
        ],
        "documents_with_no_value" => 0,
        "total_options" => 2,
        "missing_options" => 1,
        "scope" => "exclude_field_filter",
      }
    ).to eq(aggregates)
  end

  it "returns count when filtering on a field within an all_filters scope" do
    populate_content_indexes(section_count: 2)

    get "/search?q=important&aggregate_mainstream_browse_pages=2,scope:all_filters&filter_mainstream_browse_pages=browse/page/1"

    expect(parsed_response["total"]).to eq(2)
    aggregates = parsed_response["aggregates"]

    expect(
      "mainstream_browse_pages" => {
        "options" => [
          { "value" => { "slug" => "browse/page/1" }, "documents" => 2 },
        ],
        "documents_with_no_value" => 0,
        "total_options" => 1,
        "missing_options" => 0,
        "scope" => "all_filters",
      }
    ).to eq(aggregates)
  end

  it "returns examples" do
    populate_content_indexes(section_count: 2)

    get "/search?q=important&aggregate_mainstream_browse_pages=1,examples:5,example_scope:global,example_fields:link:title:mainstream_browse_pages"

    expect(["/government-1", "/mainstream-1"]).to eq(
      parsed_response["aggregates"]["mainstream_browse_pages"]["options"].first["value"]["example_info"]["examples"].map { |h| h["link"] }.sort
    )
  end

  it "returns examples before migration" do
    allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return([])

    add_sample_documents('mainstream_test', 2)
    add_sample_documents('govuk_test', 2)

    get "/search?q=important&aggregate_mainstream_browse_pages=1,examples:5,example_scope:global,example_fields:link:title:mainstream_browse_pages"

    expected_results = %w(/mainstream-1)

    options = parsed_response["aggregates"]["mainstream_browse_pages"]["options"]
    actual_results = options.first["value"]["example_info"]["examples"].map { |h| h["link"] }.sort

    expect(expected_results).to eq(actual_results)
  end

  it "returns examples after migration" do
    allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return(['answers'])

    add_sample_documents('mainstream_test', 2)
    add_sample_documents('govuk_test', 2)

    get "/search?q=important&aggregate_mainstream_browse_pages=1,examples:5,example_scope:global,example_fields:link:title:mainstream_browse_pages"

    expected_results = %w(/govuk-1)

    options = parsed_response["aggregates"]["mainstream_browse_pages"]["options"]
    actual_results = options.first["value"]["example_info"]["examples"].map { |h| h["link"] }.sort

    expect(expected_results).to eq(actual_results)
  end

  it "returns examples before migration within query scope" do
    allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return([])

    add_sample_documents('mainstream_test', 2)
    add_sample_documents('govuk_test', 2)

    get "/search?q=important&aggregate_mainstream_browse_pages=1,examples:5,example_scope:query,example_fields:link:title:mainstream_browse_pages"

    expected_results = %w(/mainstream-1)

    options = parsed_response["aggregates"]["mainstream_browse_pages"]["options"]
    actual_results = options.first["value"]["example_info"]["examples"].map { |h| h["link"] }.sort

    expect(expected_results).to eq(actual_results)
  end

  it "returns examples after migration within query scope" do
    allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return(['answers'])

    add_sample_documents('mainstream_test', 2)
    add_sample_documents('govuk_test', 2)

    get "/search?q=important&aggregate_mainstream_browse_pages=1,examples:5,example_scope:query,example_fields:link:title:mainstream_browse_pages"

    expected_results = %w(/govuk-1)

    options = parsed_response["aggregates"]["mainstream_browse_pages"]["options"]
    actual_results = options.first["value"]["example_info"]["examples"].map { |h| h["link"] }.sort

    expect(expected_results).to eq(actual_results)
  end

  it "can be searched by every aggregate for dfid" do
    commit_document("mainstream_test", dfid_research_output_attributes, type: "dfid_research_output")

    aggregate_queries = %w(
      filter_dfid_review_status[]=peer_reviewed
      filter_country[]=TZ&filter_country[]=AL
    )

    aggregate_queries.each do |filter_query|
      get "/search?filter_document_type=dfid_research_output&#{filter_query}"

      expect(last_response).to be_ok
      expect(parsed_response.fetch("total")).to eq(1), "Failure to search by #{filter_query}"
      expect(
        hash_including(
          "document_type" => "dfid_research_output",
          "title" => dfid_research_output_attributes.fetch("title"),
          "link" => dfid_research_output_attributes.fetch("link"),
        )
      ).to eq(
        parsed_response.fetch("results").fetch(0),
      )
    end
  end

  def dfid_research_output_attributes
    {
      "title" => "Somewhat Unique DFID Research Output",
      "link" => "/dfid-research-outputs/somewhat-unique-dfid-research-output",
      "indexable_content" => "Use of calcrete in gender roles in Tanzania",
      "country" => %w(TZ AL),
      "dfid_review_status" => "peer_reviewed",
      "first_published_at" => "2014-04-02",
    }
  end
end
