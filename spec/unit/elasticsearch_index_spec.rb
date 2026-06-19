require "spec_helper"

RSpec.describe SearchIndices::Index do
  include Fixtures::DefaultMappings

  before do
    @index = build_govuk_index
  end

  it "has returns the name of the index as real_name" do
    stub_request(:get, "http://example.com:9200/govuk_test/_alias")
      .to_return(
        body: { "real-name" => { "aliases" => { "govuk_test" => {} } } }.to_json,
        headers: { "Content-Type" => "application/json" },
      )

    expect(@index.real_name).to eq("real-name")
  end

  it "returns nil for real_name when elasticsearch returns a 404 response" do
    stub_request(:get, "http://example.com:9200/govuk_test/_alias")
      .to_return(
        status: 404,
        body: '{"error":"IndexMissingException[[text-index] missing]","status":404}',
        headers: { "Content-Type" => "application/json" },
      )

    expect(@index.real_name).to be_nil
  end

  it "returns nil for real_name when elasticsearch reports the index as missing" do
    # elasticsearch is weird: even though /index/_status 404s if the index
    # doesn't exist, /index/_alias returns a 200.
    stub_request(:get, "http://example.com:9200/govuk_test/_alias")
      .to_return(
        body: "{}",
        headers: { "Content-Type" => "application/json" },
      )

    expect(@index.real_name).to be_nil
  end

  it "exists" do
    stub_request(:get, "http://example.com:9200/govuk_test/_alias")
      .to_return(
        body: { "real-name" => { "aliases" => { "govuk_test" => {} } } }.to_json,
        headers: { "Content-Type" => "application/json" },
      )

    expect(@index).to be_exists
  end

  it "can be searched" do
    stub_get = stub_request(:get, "http://example.com:9200/govuk_test/generic-document/_search").with(
      body: %r{"query":"keyword search"},
    ).to_return(
      body: '{"hits":{"hits":[]}}',
      headers: { "Content-Type" => "application/json" },
    )

    @index.raw_search({ query: "keyword search" })

    assert_requested(stub_get)
  end

  it "can manually commit changes" do
    refresh_url = "http://example.com:9200/govuk_test/_refresh"
    stub_request(:post, refresh_url).to_return(
      body: '{"ok":true,"_shards":{"total":1,"successful":1,"failed":0}}',
      headers: { "Content-Type" => "application/json" },
    )

    @index.commit

    assert_requested :post, refresh_url
  end

  it "can fetch documents by format" do
    search_pattern = "http://example.com:9200/govuk_test/_search?scroll=1m&search_type=query_then_fetch&size=500&version=true"
    stub_request(:get, search_pattern).with(
      body: { query: { term: { format: "organisation" } }, _source: { includes: %w[title link] }, sort: %w[_doc] },
    ).to_return(
      body: { _scroll_id: "abcdefgh", hits: { total: 10, hits: [] } }.to_json,
      headers: { "Content-Type" => "application/json" },
    )

    hits = (1..10).map do |i|
      { "_source" => { "link" => "/organisation-#{i}", "title" => "Organisation #{i}" } }
    end
    stub_request(:get, scroll_uri("abcdefgh")).to_return(
      body: scroll_response_body("abcdefgh", 10, hits),
      headers: { "Content-Type" => "application/json" },
    ).then.to_return(
      body: scroll_response_body("abcdefgh", 10, []),
      headers: { "Content-Type" => "application/json" },
    ).then.to_raise("should never happen")

    result = @index.documents_by_format("organisation", sample_field_definitions(%w[link title]))
    expect((1..10).map { |i| "Organisation #{i}" }).to eq(result.map { |r| r["title"] })
  end

  it "can fetch documents by format with certain fields" do
    search_pattern = "http://example.com:9200/govuk_test/_search?scroll=1m&search_type=query_then_fetch&size=500&version=true"

    stub_request(:get, search_pattern).with(
      body: "{\"query\":{\"term\":{\"format\":\"organisation\"}},\"_source\":{\"includes\":[\"title\",\"link\"]},\"sort\":[\"_doc\"]}",
    ).to_return(
      body: { _scroll_id: "abcdefgh", hits: { total: 10, hits: [] } }.to_json,
      headers: { "Content-Type" => "application/json" },
    )

    hits = (1..10).map do |i|
      { "_source" => { "link" => "/organisation-#{i}", "title" => "Organisation #{i}" } }
    end
    stub_request(:get, scroll_uri("abcdefgh")).to_return(
      body: scroll_response_body("abcdefgh", 10, hits),
      headers: { "Content-Type" => "application/json" },
    ).then.to_return(
      body: scroll_response_body("abcdefgh", 10, []),
      headers: { "Content-Type" => "application/json" },
    ).then.to_raise("should never happen")

    result = @index.documents_by_format("organisation", sample_field_definitions(%w[link title])).to_a
    expect((1..10).map { |i| "Organisation #{i}" }).to eq(result.map { |r| r["title"] })
    expect((1..10).map { |i| "/organisation-#{i}" }).to eq(result.map { |r| r["link"] })
  end

private

  def scroll_uri(scroll_id)
    "http://example.com:9200/_search/scroll?scroll=1m&scroll_id=#{scroll_id}"
  end

  def scroll_response_body(scroll_id, total_results, results)
    {
      _scroll_id: scroll_id,
      hits: { total: total_results, hits: results },
    }.to_json
  end

  def build_govuk_index
    base_uri = "http://example.com:9200"
    search_config = SearchConfig.default_instance
    described_class.new(base_uri, "govuk_test", "govuk_test", search_config)
  end

  def stub_popularity_index_requests(paths, popularity, total_pages = 10, total_requested = total_pages, paths_to_return = paths)
    # stub the request for total results
    stub_request(:get, "http://example.com:9200/page-traffic_test/generic-document/_search")
      .with(body: { "query" => { "match_all" => {} }, "size" => 0 }.to_json)
      .to_return(
        body: { "hits" => { "total" => total_pages } }.to_json,

        headers: { "Content-Type" => "application/json" },
      )

    # stub the search for popularity data
    expected_query = {
      "query" => {
        "terms" => {
          "path_components" => paths,
        },
      },
      "_source" => { "includes" => %w[rank_14 vc_14] },
      "sort" => [
        { "rank_14" => { "order" => "asc" } },
      ],
      "size" => total_requested,
    }
    response = {
      "hits" => {
        "hits" => paths_to_return.map do |path|
          {
            "_id" => path,
            "_source" => {
              "rank_14" => popularity,
              "vc_14" => popularity,
            },
          }
        end,
      },
    }

    stub_request(:get, "http://example.com:9200/page-traffic_test/generic-document/_search")
      .with(body: expected_query.to_json)
      .to_return(
        body: response.to_json,

        headers: { "Content-Type" => "application/json" },
      )
  end

  def stub_traffic_index
    base_uri = "http://example.com:9200"
    search_config = SearchConfig.default_instance
    traffic_index = described_class.new(base_uri, "page-traffic_test", "page-traffic_test", page_traffic_mappings, search_config)
    allow_any_instance_of(Indexer::PopularityLookup).to receive(:traffic_index).and_return(traffic_index)
    allow(traffic_index).to receive(:real_name).and_return("page-traffic_test")
  end

  def expected_all_documents_query
    {
      "bool" => {
        "must_not" => {
          "terms" => {
            "format" => [],
          },
        },
      },
    }
  end
end
