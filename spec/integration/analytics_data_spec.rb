require 'spec_helper'

RSpec.describe 'AnalyticsDataTest' do
  before do
    allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return({})
    @analytics_data_fetcher = AnalyticsData.new(SearchConfig.default_instance.base_uri, %w(government_test govuk_test))
  end

  it "fetches rows of analytics dimensions" do
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
    commit_document("government_test", document)

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

  it "only includes migrated formats from the govuk index" do
    allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return("answers" => :all)

    document = {
      "content_id" => "587b0635-2911-49e6-af68-3f0ea1b07cc5",
      "link" => "/an-example-page",
      "content_store_document_type" => "some_document_type",
      "primary_publishing_organisation" => %w(some_publishing_org),
      "organisations" => %w(some_org another_org yet_another_org),
      "navigation_document_supertype" => "some_navigation_supertype",
      "user_journey_document_supertype" => "some_user_journey_supertype",
      "public_timestamp" => "2017-06-20T10:21:55.000+01:00",
      "format" => "answers",
    }
    commit_document("government_test", document.merge("title" => "government title",))
    commit_document("govuk_test", document.merge("title" => "govuk title",))

    rows = @analytics_data_fetcher.rows

    expected_row = [
      "587b0635-2911-49e6-af68-3f0ea1b07cc5",
      "/an-example-page",
      "some_publishing_org",
      nil,
      "govuk title",
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

  it "missing data is nil" do
    document = {}
    id = commit_document("government_test", document)

    rows = @analytics_data_fetcher.rows

    expected_row = [id, id, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]

    expect(rows.to_a).to eq([expected_row])
  end

  it "content_id is preferred to link for product id" do
    document = {
      "content_id" => "some_content_id",
      "link" => "/some/page/path",
    }
    commit_document("government_test", document)

    rows = @analytics_data_fetcher.rows

    expect(rows.first[0]).to eq("some_content_id")
  end

  it "product id falls back to link if content_id is missing" do
    document = {
      "link" => "/some/page/path",
    }
    commit_document("government_test", document)

    rows = @analytics_data_fetcher.rows

    expect(rows.first[0]).to eq("/some/page/path")
  end

  it "document_type is preferred to format" do
    document = {
      "format" => "some_format",
      "content_store_document_type" => "some_document_type",
    }
    commit_document("government_test", document)

    rows = @analytics_data_fetcher.rows

    expect(rows.first[5]).to eq("some_document_type")
  end

  it "document_type falls back to format if not present" do
    document = {
      "format" => "some_format",
    }
    commit_document("government_test", document)

    rows = @analytics_data_fetcher.rows

    expect(rows.first[5]).to eq("some_format")
  end

  it "sanitises unix line breaks in titles" do
    document = {
      "title" => <<~HEREDOC
        A page title
        with some
        line breaks
        HEREDOC
    }
    commit_document("government_test", document)

    rows = @analytics_data_fetcher.rows

    expect(rows.first[4]).to eq("A page title with some line breaks")
  end

  it "sanitises windows line breaks in titles" do
    document = {
      "title" => "A page title\r\nwith some\r\nline breaks"
    }
    commit_document("government_test", document)

    rows = @analytics_data_fetcher.rows

    expect(rows.first[4]).to eq("A page title with some line breaks")
  end

  it "fetches all rows" do
    fixture_file = File.expand_path("../fixtures/content_for_analytics.json", __FILE__)
    documents = JSON.parse(File.read(fixture_file))
    documents.each do |document|
      commit_document("government_test", document)
    end

    analytics_data = @analytics_data_fetcher.rows.to_a

    expect(analytics_data.size).to eq(30)
  end

  it "headers and rows are consisent" do
    document = {
      "content_id" => "587b0635-2911-49e6-af68-3f0ea1b07cc5",
      "link" => "/an-example-page",
      "popularity": 0.5,
    }
    commit_document("government_test", document)

    rows = @analytics_data_fetcher.rows
    headers = @analytics_data_fetcher.headers

    expect(headers.size).to eq(rows.first.size)
  end
end
