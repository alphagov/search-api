require "spec_helper"

RSpec.describe SearchIndices::Index do
  include Fixtures::DefaultMappings

  before do
    @index = build_government_index
  end

  it "has returns the name of the index as real_name" do
    stub_request(:get, "http://example.com:9200/government_test/_alias")
      .to_return(
        body: { "real-name" => { "aliases" => { "government_test" => {} } } }.to_json,
        headers: { "Content-Type" => "application/json" },
      )

    expect(@index.real_name).to eq("real-name")
  end

  it "returns nil for real_name when elasticsearch returns a 404 response" do
    stub_request(:get, "http://example.com:9200/government_test/_alias")
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
    stub_request(:get, "http://example.com:9200/government_test/_alias")
      .to_return(
        body: "{}",
        headers: { "Content-Type" => "application/json" },
      )

    expect(@index.real_name).to be_nil
  end

  it "exists" do
    stub_request(:get, "http://example.com:9200/government_test/_alias")
      .to_return(
        body: { "real-name" => { "aliases" => { "government_test" => {} } } }.to_json,
        headers: { "Content-Type" => "application/json" },
      )

    expect(@index).to be_exists
  end

  it "raises error for failures in bulk update" do
    stub_tagging_lookup
    stub_traffic_index
    stub_popularity_index_requests(["/foo/bar", "/foo/baz"], 1.0, 20)

    json_documents = [
      { "document_type" => "edition", "link" => "/foo/bar", "title" => "TITLE ONE", "popularity" => "0.09090909090909091", "view_count" => "1" },
      { "document_type" => "edition", "link" => "/foo/baz", "title" => "TITLE TWO", "popularity" => "0.09090909090909091", "view_count" => "2" },
    ]

    documents = json_documents.map do |json_document|
      double("document", elasticsearch_export: json_document)
    end

    response = <<~RESPONSE
      {"took":0,"items":[
        { "index": { "_index":"government_test", "_type":"generic-document", "_id":"/foo/bar", "ok":true } },
        { "index": { "_index":"government_test", "_type":"generic-document", "_id":"/foo/baz", "error":"stuff" } }
      ]}
    RESPONSE
    stub_request(:post, "http://example.com:9200/government_test/_bulk").to_return(
      body: response,
      headers: { "Content-Type" => "application/json" },
    )

    begin
      @index.add(documents)
      flunk("No exception raised")
    rescue Indexer::BulkIndexFailure => e
      expect(e.message).to eq("Indexer::BulkIndexFailure")
    end
  end

  it "can be searched" do
    stub_get = stub_request(:get, "http://example.com:9200/government_test/generic-document/_search").with(
      body: %r{"query":"keyword search"},
    ).to_return(
      body: '{"hits":{"hits":[]}}',
      headers: { "Content-Type" => "application/json" },
    )

    @index.raw_search({ query: "keyword search" })

    assert_requested(stub_get)
  end

  it "can manually commit changes" do
    refresh_url = "http://example.com:9200/government_test/_refresh"
    stub_request(:post, refresh_url).to_return(
      body: '{"ok":true,"_shards":{"total":1,"successful":1,"failed":0}}',
      headers: { "Content-Type" => "application/json" },
    )

    @index.commit

    assert_requested :post, refresh_url
  end

  it "can fetch documents by format" do
    search_pattern = "http://example.com:9200/government_test/_search?scroll=1m&search_type=query_then_fetch&size=500&version=true"
    stub_request(:get, search_pattern).with(
      body: { query: { term: { format: "organisation" } }, _source: { includes: %w{title link} }, sort: %w[_doc] },
    ).to_return(
      body: { _scroll_id: "abcdefgh", hits: { total: 10, hits: [] } }.to_json,
      headers: { "Content-Type" => "application/json" },
    )

    hits = (1..10).map { |i|
      { "_source" => { "link" => "/organisation-#{i}", "title" => "Organisation #{i}" } }
    }
    stub_request(:get, scroll_uri("abcdefgh")).to_return(
      body: scroll_response_body("abcdefgh", 10, hits),
      headers: { "Content-Type" => "application/json" },
    ).then.to_return(
      body: scroll_response_body("abcdefgh", 10, []),
      headers: { "Content-Type" => "application/json" },
    ).then.to_raise("should never happen")

    result = @index.documents_by_format("organisation", sample_field_definitions(%w(link title)))
    expect((1..10).map { |i| "Organisation #{i}" }).to eq(result.map { |r| r["title"] })
  end

  it "can fetch documents by format with certain fields" do
    search_pattern = "http://example.com:9200/government_test/_search?scroll=1m&search_type=query_then_fetch&size=500&version=true"

    stub_request(:get, search_pattern).with(
      body: "{\"query\":{\"term\":{\"format\":\"organisation\"}},\"_source\":{\"includes\":[\"title\",\"link\"]},\"sort\":[\"_doc\"]}",
    ).to_return(
      body: { _scroll_id: "abcdefgh", hits: { total: 10, hits: [] } }.to_json,
      headers: { "Content-Type" => "application/json" },
    )

    hits = (1..10).map { |i|
      { "_source" => { "link" => "/organisation-#{i}", "title" => "Organisation #{i}" } }
    }
    stub_request(:get, scroll_uri("abcdefgh")).to_return(
      body: scroll_response_body("abcdefgh", 10, hits),
      headers: { "Content-Type" => "application/json" },
    ).then.to_return(
      body: scroll_response_body("abcdefgh", 10, []),
      headers: { "Content-Type" => "application/json" },
    ).then.to_raise("should never happen")

    result = @index.documents_by_format("organisation", sample_field_definitions(%w(link title))).to_a
    expect((1..10).map { |i| "Organisation #{i}" }).to eq(result.map { |r| r["title"] })
    expect((1..10).map { |i| "/organisation-#{i}" }).to eq(result.map { |r| r["link"] })
  end

  it "can count the documents without retrieving them all" do
    search_pattern = "http://example.com:9200/government_test/_search?scroll=1m&search_type=query_then_fetch&size=50&version=true"
    stub_request(:get, search_pattern).with(
      body: { query: expected_all_documents_query, sort: %w[_doc] }.to_json,
    ).to_return(
      body: { _scroll_id: "abcdefgh", hits: { total: 100 } }.to_json,
      headers: { "Content-Type" => "application/json" },
    ).then.to_raise("should never happen")
    expect(@index.all_documents.size).to eq(100)
  end

  it "can retrieve all documents" do
    search_uri = "http://example.com:9200/government_test/_search?scroll=1m&search_type=query_then_fetch&size=50&version=true"

    stub_request(:get, search_uri).with(
      body: { query: expected_all_documents_query, sort: %w[_doc] }.to_json,
    ).to_return(
      body: { _scroll_id: "abcdefgh", hits: { total: 100, hits: [] } }.to_json,
      headers: { "Content-Type" => "application/json" },
    )
    hits = (1..100).map { |i|
      { "_source" => { "link" => "/foo-#{i}", "document_type" => "edition" }, "_type" => "generic-document" }
    }
    stub_request(:get, scroll_uri("abcdefgh")).to_return(
      body: scroll_response_body("abcdefgh", 100, hits[0, 50]),
      headers: { "Content-Type" => "application/json" },
    ).then.to_return(
      body: scroll_response_body("abcdefgh", 100, hits[50, 50]),
      headers: { "Content-Type" => "application/json" },
    ).then.to_return(
      body: scroll_response_body("abcdefgh", 100, []),
      headers: { "Content-Type" => "application/json" },
    ).then.to_raise("should never happen")
    all_documents = @index.all_documents.to_a
    expect(all_documents.size).to eq(100)
    expect(all_documents.first.link).to eq("/foo-1")
    expect(all_documents.last.link).to eq("/foo-100")
  end

  it "can scroll through the documents" do
    search_uri = "http://example.com:9200/government_test/_search?scroll=1m&search_type=query_then_fetch&size=2&version=true"

    allow(described_class).to receive(:scroll_batch_size).and_return(2)

    stub_request(:get, search_uri).with(
      body: { query: expected_all_documents_query, sort: %w[_doc] }.to_json,
    ).to_return(
      body: { _scroll_id: "abcdefgh", hits: { total: 3, hits: [] } }.to_json,

      headers: { "Content-Type" => "application/json" },
    )
    hits = (1..3).map { |i|
      { "_source" => { "link" => "/foo-#{i}", "document_type" => "edition" }, "_type" => "generic-document" }
    }
    total = hits.size

    stub_request(:get, scroll_uri("abcdefgh")).to_return(
      body: scroll_response_body("ijklmnop", total, hits[0, 2]),

      headers: { "Content-Type" => "application/json" },
    ).then.to_raise("should never happen")

    stub_request(:get, scroll_uri("ijklmnop")).to_return(
      body: scroll_response_body("qrstuvwx", total, hits[2, 1]),

      headers: { "Content-Type" => "application/json" },
    ).then.to_raise("should never happen")

    stub_request(:get, scroll_uri("qrstuvwx")).to_return(
      body: scroll_response_body("yz", total, []),

      headers: { "Content-Type" => "application/json" },
    ).then.to_raise("should never happen")

    all_documents = @index.all_documents.to_a
    expect(all_documents.map(&:link)).to eq(["/foo-1", "/foo-2", "/foo-3"])
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

  def build_government_index
    base_uri = "http://example.com:9200"
    search_config = SearchConfig.default_instance
    described_class.new(base_uri, "government_test", "government_test", default_mappings, search_config)
  end

  def stub_popularity_index_requests(paths, popularity, total_pages = 10, total_requested = total_pages, paths_to_return = paths)
    # stub the request for total results
    stub_request(:get, "http://example.com:9200/page-traffic_test/generic-document/_search").
      with(body: { "query" => { "match_all" => {} }, "size" => 0 }.to_json).
      to_return(
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
        "hits" => paths_to_return.map { |path|
          {
            "_id" => path,
            "_source" => {
              "rank_14" => popularity,
              "vc_14" => popularity,
            },
          }
        },
      },
    }

    stub_request(:get, "http://example.com:9200/page-traffic_test/generic-document/_search").
      with(body: expected_query.to_json).
      to_return(
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
