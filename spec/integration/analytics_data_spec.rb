require 'spec_helper'

RSpec.describe 'AnalyticsDataTest', tags: ['integration'] do
  before do
    @analytics_data_fetcher = AnalyticsData.new(SearchConfig.instance.base_uri, ["mainstream_test"])
  end

  it "fetches_rows_of_analytics_dimensions" do
    document = {
      "content_id" => "587b0635-2911-49e6-af68-3f0ea1b07cc5",
      "link" => "/an-example-page",
      "title" => "some page title",
      "content_store_document_type" => "some_document_type",
      "primary_publishing_organisation" => %w(some_publishing_org),
      "organisations" => %w(some_org another_org yet_another_org),
      "navigation_document_supertype" => "some_navigation_supertype",
      "user_journey_document_supertype" => "some_user_journey_supertype",
      "public_timestamp" => "2017-06-20T10:21:55.000+01:00",
    }
    commit_document("mainstream_test", document)

    rows = @analytics_data_fetcher.rows

    expected_row = [
        "587b0635-2911-49e6-af68-3f0ea1b07cc5",
        "/an-example-page",
        "some_publishing_org",
        nil,
        "some page title",
        "some_document_type",
        "some_navigation_supertype",
        nil,
        "some_user_journey_supertype",
        "some_org, another_org, yet_another_org",
        "20170620",
        nil,
        nil,
      ]

    expect(rows.to_a).to eq([expected_row])
  end

  it "missing_data_is_nil" do
    document = {}
    id = commit_document("mainstream_test", document)

    rows = @analytics_data_fetcher.rows

    expected_row = [id, id, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]

    expect(rows.to_a).to eq([expected_row])
  end

  it "content_id_is_preferred_to_link_for_product_id" do
    document = {
      "content_id" => "some_content_id",
      "link" => "/some/page/path",
    }
    commit_document("mainstream_test", document)

    rows = @analytics_data_fetcher.rows

    expect(rows.first[0]).to eq("some_content_id")
  end

  it "product_id_falls_back_to_link_if_content_id_is_missing" do
    document = {
      "link" => "/some/page/path",
    }
    commit_document("mainstream_test", document)

    rows = @analytics_data_fetcher.rows

    expect(rows.first[0]).to eq("/some/page/path")
  end

  it "document_type_is_preferred_to_format" do
    document = {
      "format" => "some_format",
      "content_store_document_type" => "some_document_type",
    }
    commit_document("mainstream_test", document)

    rows = @analytics_data_fetcher.rows

    expect(rows.first[5]).to eq("some_document_type")
  end

  it "document_type_falls_back_to_format_if_not_present" do
    document = {
      "format" => "some_format",
    }
    commit_document("mainstream_test", document)

    rows = @analytics_data_fetcher.rows

    expect(rows.first[5]).to eq("some_format")
  end

  it "sanitises_unix_line_breaks_in_titles" do
    document = {
      "title" => <<~HEREDOC
        A page title
        with some
        line breaks
        HEREDOC
    }
    commit_document("mainstream_test", document)

    rows = @analytics_data_fetcher.rows

    expect(rows.first[4]).to eq("A page title with some line breaks")
  end

  it "sanitises_windows_line_breaks_in_titles" do
    document = {
      "title" => "A page title\r\nwith some\r\nline breaks"
    }
    commit_document("mainstream_test", document)

    rows = @analytics_data_fetcher.rows

    expect(rows.first[4]).to eq("A page title with some line breaks")
  end

  it "fetches_all_rows" do
    fixture_file = File.expand_path("../fixtures/content_for_analytics.json", __FILE__)
    documents = JSON.parse(File.read(fixture_file))
    documents.each do |document|
      commit_document("mainstream_test", document)
    end

    analytics_data = @analytics_data_fetcher.rows.to_a

    expect(analytics_data.size).to eq(30)
  end

  it "headers_and_rows_are_consisent" do
    document = {
      "content_id" => "587b0635-2911-49e6-af68-3f0ea1b07cc5",
      "link" => "/an-example-page",
      "popularity": 0.5,
    }
    commit_document("mainstream_test", document)

    rows = @analytics_data_fetcher.rows
    headers = @analytics_data_fetcher.headers

    expect(headers.size).to eq(rows.first.size)
  end
end
