require 'spec_helper'

RSpec.describe SearchIndices::Index do
  include Fixtures::DefaultMappings

  before do
    @index = build_mainstream_index
  end

  it "real_name" do
    stub_request(:get, "http://example.com:9200/mainstream_test/_aliases")
      .to_return(
        body: { "real-name" => { "aliases" => { "mainstream_test" => {} } } }.to_json,
        headers: { 'Content-Type' => 'application/json' },
      )

    expect("real-name").to eq(@index.real_name)
  end

  it "real_name_when_no_index" do
    stub_request(:get, "http://example.com:9200/mainstream_test/_aliases")
      .to_return(
        status: 404,
        body: '{"error":"IndexMissingException[[text-index] missing]","status":404}',
        headers: { 'Content-Type' => 'application/json' },
      )

    expect(@index.real_name).to be_nil
  end

  it "real_name_when_no_index_es0_20" do
    # elasticsearch is weird: even though /index/_status 404s if the index
    # doesn't exist, /index/_aliases returns a 200.
    stub_request(:get, "http://example.com:9200/mainstream_test/_aliases")
      .to_return(
        body: "{}",
        headers: { 'Content-Type' => 'application/json' },
      )

    expect(@index.real_name).to be_nil
  end

  it "exists" do
    stub_request(:get, "http://example.com:9200/mainstream_test/_aliases")
      .to_return(
        body: { "real-name" => { "aliases" => { "mainstream_test" => {} } } }.to_json,
        headers: { 'Content-Type' => 'application/json' },
      )

    expect(@index).to be_exists
  end

  it "should_raise_error_for_failures_in_bulk_update" do
    stub_tagging_lookup
    stub_traffic_index
    stub_popularity_index_requests(["/foo/bar", "/foo/baz"], 1.0, 20)

    json_documents = [
      { "_type" => "edition", "link" => "/foo/bar", "title" => "TITLE ONE", "popularity" => "0.09090909090909091" },
      { "_type" => "edition", "link" => "/foo/baz", "title" => "TITLE TWO", "popularity" => "0.09090909090909091" }
    ]

    documents = json_documents.map do |json_document|
      double("document", elasticsearch_export: json_document)
    end

    response = <<-eos
{"took":0,"items":[
  { "index": { "_index":"mainstream_test", "_type":"edition", "_id":"/foo/bar", "ok":true } },
  { "index": { "_index":"mainstream_test", "_type":"edition", "_id":"/foo/baz", "error":"stuff" } }
]}
    eos
    stub_request(:post, "http://example.com:9200/mainstream_test/_bulk").to_return(
      body: response,
      headers: { 'Content-Type' => 'application/json' },
    )

    begin
      @index.add(documents)
      flunk("No exception raised")
    rescue Indexer::BulkIndexFailure => e
      expect("Indexer::BulkIndexFailure").to eq(e.message)
    end
  end

  it "raw_search" do
    stub_get = stub_request(:get, "http://example.com:9200/mainstream_test/_search").with(
      body: %r{"query":"keyword search"},
    ).to_return(
      body: '{"hits":{"hits":[]}}',
      headers: { 'Content-Type' => 'application/json' },
    )

    @index.raw_search({ query: "keyword search" })

    assert_requested(stub_get)
  end

  it "raw_search_with_type" do
    stub_get = stub_request(:get, "http://example.com:9200/mainstream_test/test-type/_search").with(
      body: %r{"query":"keyword search"},
    ).to_return(
      body: '{"hits":{"hits":[]}}',
      headers: { 'Content-Type' => 'application/json' },
    )

    @index.raw_search({ query: "keyword search" }, "test-type")

    assert_requested(stub_get)
  end

  it "commit" do
    refresh_url = "http://example.com:9200/mainstream_test/_refresh"
    stub_request(:post, refresh_url).to_return(
      body: '{"ok":true,"_shards":{"total":1,"successful":1,"failed":0}}',
      headers: { 'Content-Type' => 'application/json' },
    )

    @index.commit

    assert_requested :post, refresh_url
  end

  it "can_fetch_documents_by_format" do
    search_pattern = "http://example.com:9200/mainstream_test/_search?scroll=1m&search_type=scan&size=500&version=true"
    stub_request(:get, search_pattern).with(
      body: { query: { term: { format: "organisation" } }, fields: %w{title link} }
    ).to_return(
      body: { _scroll_id: "abcdefgh", hits: { total: 10, hits: [] } }.to_json,
      headers: { 'Content-Type' => 'application/json' },
    )

    hits = (1..10).map { |i|
      { "fields" => { "link" => "/organisation-#{i}", "title" => "Organisation #{i}" } }
    }
    stub_request(:get, scroll_uri).with(
      body: "abcdefgh"
    ).to_return(
      body: scroll_response_body("abcdefgh", 10, hits),
      headers: { 'Content-Type' => 'application/json' },
    ).then.to_return(
      body: scroll_response_body("abcdefgh", 10, []),
      headers: { 'Content-Type' => 'application/json' },
    ).then.to_raise("should never happen")

    result = @index.documents_by_format("organisation", sample_field_definitions(%w(link title)))
    expect((1..10).map { |i| "Organisation #{i}" }).to eq(result.map { |r| r['title'] })
  end

  it "can_fetch_documents_by_format_with_certain_fields" do
    search_pattern = "http://example.com:9200/mainstream_test/_search?scroll=1m&search_type=scan&size=500&version=true"

    stub_request(:get, search_pattern).with(
      body: "{\"query\":{\"term\":{\"format\":\"organisation\"}},\"fields\":[\"title\",\"link\"]}"
    ).to_return(
      body: { _scroll_id: "abcdefgh", hits: { total: 10, hits: [] } }.to_json,
      headers: { 'Content-Type' => 'application/json' },
    )

    hits = (1..10).map { |i|
      { "fields" => { "link" => "/organisation-#{i}", "title" => "Organisation #{i}" } }
    }
    stub_request(:get, scroll_uri).with(
      body: "abcdefgh"
    ).to_return(
      body: scroll_response_body("abcdefgh", 10, hits),
      headers: { 'Content-Type' => 'application/json' },
    ).then.to_return(
      body: scroll_response_body("abcdefgh", 10, []),
      headers: { 'Content-Type' => 'application/json' },
    ).then.to_raise("should never happen")

    result = @index.documents_by_format("organisation", sample_field_definitions(%w(link title))).to_a
    expect((1..10).map { |i| "Organisation #{i}" }).to eq(result.map { |r| r['title'] })
    expect((1..10).map { |i| "/organisation-#{i}" }).to eq(result.map { |r| r['link'] })
  end

  it "all_documents_size" do
    # Test that we can count the documents without retrieving them all
    search_pattern = "http://example.com:9200/mainstream_test/_search?scroll=1m&search_type=scan&size=50&version=true"
    stub_request(:get, search_pattern).with(
      body: { query: expected_all_documents_query }.to_json
    ).to_return(
      body: { _scroll_id: "abcdefgh", hits: { total: 100 } }.to_json,
      headers: { 'Content-Type' => 'application/json' },
    ).then.to_raise("should never happen")
    expect(@index.all_documents.size).to eq(100)
  end

  it "all_documents" do
    search_uri = "http://example.com:9200/mainstream_test/_search?scroll=1m&search_type=scan&size=50&version=true"

    stub_request(:get, search_uri).with(
      body: { query: expected_all_documents_query }.to_json
    ).to_return(
      body: { _scroll_id: "abcdefgh", hits: { total: 100, hits: [] } }.to_json,
      headers: { 'Content-Type' => 'application/json' },
    )
    hits = (1..100).map { |i|
      { "_source" => { "link" => "/foo-#{i}" }, "_type" => "edition" }
    }
    stub_request(:get, scroll_uri).with(
      body: "abcdefgh"
    ).to_return(
      body: scroll_response_body("abcdefgh", 100, hits[0, 50]),
      headers: { 'Content-Type' => 'application/json' },
    ).then.to_return(
      body: scroll_response_body("abcdefgh", 100, hits[50, 50]),
      headers: { 'Content-Type' => 'application/json' },
    ).then.to_return(
      body: scroll_response_body("abcdefgh", 100, []),
      headers: { 'Content-Type' => 'application/json' },
    ).then.to_raise("should never happen")
    all_documents = @index.all_documents.to_a
    expect(100).to eq(all_documents.size)
    expect("/foo-1").to eq(all_documents.first.link)
    expect("/foo-100").to eq(all_documents.last.link)
  end

  it "changing_scroll_id" do
    search_uri = "http://example.com:9200/mainstream_test/_search?scroll=1m&search_type=scan&size=2&version=true"

    allow(SearchIndices::Index).to receive(:scroll_batch_size).and_return(2)

    stub_request(:get, search_uri).with(
      body: { query: expected_all_documents_query }.to_json
    ).to_return(
      body: { _scroll_id: "abcdefgh", hits: { total: 3, hits: [] } }.to_json,

      headers: { 'Content-Type' => 'application/json' },
    )
    hits = (1..3).map { |i|
      { "_source" => { "link" => "/foo-#{i}" }, "_type" => "edition" }
    }
    total = hits.size

    stub_request(:get, scroll_uri).with(
      body: "abcdefgh"
    ).to_return(
      body: scroll_response_body("ijklmnop", total, hits[0, 2]),

      headers: { 'Content-Type' => 'application/json' },
    ).then.to_raise("should never happen")

    stub_request(:get, scroll_uri).with(
      body: "ijklmnop"
    ).to_return(
      body: scroll_response_body("qrstuvwx", total, hits[2, 1]),

      headers: { 'Content-Type' => 'application/json' },
    ).then.to_raise("should never happen")

    stub_request(:get, scroll_uri).with(
      body: "qrstuvwx"
    ).to_return(
      body: scroll_response_body("yz", total, []),

      headers: { 'Content-Type' => 'application/json' },
    ).then.to_raise("should never happen")

    all_documents = @index.all_documents.to_a
    expect(["/foo-1", "/foo-2", "/foo-3"]).to eq(all_documents.map(&:link))
  end

private

  def scroll_uri
    "http://example.com:9200/_search/scroll?scroll=1m"
  end

  def scroll_response_body(scroll_id, total_results, results)
    {
      _scroll_id: scroll_id,
      hits: { total: total_results, hits: results }
    }.to_json
  end

  def build_mainstream_index
    base_uri = URI.parse("http://example.com:9200")
    search_config = SearchConfig.new
    described_class.new(base_uri, "mainstream_test", "mainstream_test", default_mappings, search_config)
  end

  def stub_popularity_index_requests(paths, popularity, total_pages = 10, total_requested = total_pages, paths_to_return = paths)
    # stub the request for total results
    stub_request(:get, "http://example.com:9200/page-traffic_test/_search").
      with(body: { "query" => { "match_all" => {} }, "size" => 0 }.to_json).
      to_return(
        body: { "hits" => { "total" => total_pages } }.to_json,

        headers: { 'Content-Type' => 'application/json' },
      )

    # stub the search for popularity data
    expected_query = {
      "query" => {
        "terms" => {
          "path_components" => paths,
        },
      },
      "fields" => ["rank_14"],
      "sort" => [
        { "rank_14" => { "order" => "asc" } }
      ],
      "size" => total_requested
    }
    response = {
      "hits" => {
        "hits" => paths_to_return.map {|path|
          {
            "_id" => path,
            "fields" => {
              "rank_14" => popularity
            }
          }
        }
      }
    }

    stub_request(:get, "http://example.com:9200/page-traffic_test/_search").
      with(body: expected_query.to_json).
      to_return(
        body: response.to_json,

        headers: { 'Content-Type' => 'application/json' },
      )
  end

  def stub_traffic_index
    base_uri = URI.parse("http://example.com:9200")
    search_config = SearchConfig.new
    traffic_index = described_class.new(base_uri, "page-traffic_test", "page-traffic_test", page_traffic_mappings, search_config)
    allow_any_instance_of(Indexer::PopularityLookup).to receive(:traffic_index).and_return(traffic_index)
    allow(traffic_index).to receive(:real_name).and_return("page-traffic_test")
  end

  def expected_all_documents_query
    {
      "bool" => {
        "must_not" => {
          "terms" => {
            "format" => []
          }
        }
      }
    }
  end
end
