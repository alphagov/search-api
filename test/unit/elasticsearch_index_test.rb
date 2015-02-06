require "test_helper"
require "elasticsearch/index"
require "search_config"
require "webmock"

class ElasticsearchIndexTest < MiniTest::Unit::TestCase
  include Fixtures::DefaultMappings

  def setup
    @base_uri = URI.parse("http://example.com:9200")
    search_config = SearchConfig.new
    @wrapper = Elasticsearch::Index.new(@base_uri, "test-index", default_mappings, search_config)

    @traffic_index = Elasticsearch::Index.new(@base_uri, "page-traffic", page_traffic_mappings, search_config)
    @wrapper.stubs(:traffic_index).returns(@traffic_index)
    @traffic_index.stubs(:real_name).returns("page-traffic")
  end

  def stub_popularity_index_requests(paths, popularity, total_pages=10, total_requested=total_pages, paths_to_return=paths)
    # stub the request for total results
    stub_request(:get, "http://example.com:9200/page-traffic/_search").
            with(:body => { "query" => { "match_all" => {}}, "size" => 0 }.to_json).
            to_return(:status => 200, :body => { "hits" => { "total" => total_pages }}.to_json)

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

    stub_request(:get, "http://example.com:9200/page-traffic/_search").
            with(:body => expected_query.to_json).
            to_return(:status => 200, :body => response.to_json, :headers => {})
  end

  def successful_response
    <<-eos
{"took":5,"items":[
  { "index": { "_index":"test-index", "_type":"edition", "_id":"/foo/bar", "ok":true } }
]}
    eos
  end

  def test_real_name
    stub_request(:get, "http://example.com:9200/test-index/_aliases")
      .to_return(
        body: MultiJson.encode({"real-name" => { "aliases" => { "test-index" => {} } }}),
        headers: {"Content-Type" => "application/json"}
      )

    assert_equal "real-name", @wrapper.real_name
  end

  def test_real_name_when_no_index
    stub_request(:get, "http://example.com:9200/test-index/_aliases")
      .to_return(
        status: 404,
        body: '{"error":"IndexMissingException[[text-index] missing]","status":404}',
        headers: {"Content-Type" => "application/json; charset=UTF-8",
                  "Content-Length" => 68}
      )

    assert_nil @wrapper.real_name
  end

  def test_real_name_when_no_index_es0_20
    # elasticsearch is weird: even though /index/_status 404s if the index
    # doesn't exist, /index/_aliases returns a 200.
    stub_request(:get, "http://example.com:9200/test-index/_aliases")
      .to_return(
        status: 200,
        body: "{}",
        headers: {"Content-Type" => "application/json"}
      )

    assert_nil @wrapper.real_name
  end

  def test_exists
    stub_request(:get, "http://example.com:9200/test-index/_aliases")
      .to_return(
        body: MultiJson.encode({"real-name" => { "aliases" => { "test-index" => {} } }}),
        headers: {"Content-Type" => "application/json"}
      )

    assert @wrapper.exists?
  end

  def test_exists_when_no_index
    stub_request(:get, "http://example.com:9200/test-index/_aliases")
      .to_return(
        status: 404,
        body: '{"error":"IndexMissingException[[text-index] missing]","status":404}',
        headers: {"Content-Type" => "application/json; charset=UTF-8",
                  "Content-Length" => 68}
      )

    refute @wrapper.exists?
  end

  def test_exists_when_no_index_es0_20
    # elasticsearch was weird before version 0.90: even though /index/_status
    # 404s if the index doesn't exist, /index/_aliases returned a 200.
    stub_request(:get, "http://example.com:9200/test-index/_aliases")
      .to_return(
        status: 200,
        body: "{}",
        headers: {"Content-Type" => "application/json"}
      )

    refute @wrapper.exists?
  end

  def test_should_bulk_update_documents
    stub_popularity_index_requests(["/foo/bar"], 1.0)

    # TODO: factor out with FactoryGirl
    json_document = {
        "_type" => "edition",
        "link" => "/foo/bar",
        "title" => "TITLE ONE",
    }
    document = stub("document", elasticsearch_export: json_document)
    # Note that this comes with a trailing newline, which elasticsearch needs
    payload = <<-eos
{"index":{"_type":"edition","_id":"/foo/bar"}}
{"_type":"edition","link":"/foo/bar","title":"TITLE ONE","popularity":1.0,"tags":[],"format":"edition"}
    eos
    response = <<-eos
{"took":5,"items":[
  { "index": { "_index":"test-index", "_type":"edition", "_id":"/foo/bar", "ok":true } }
]}
    eos
    stub_request(:post, "http://example.com:9200/test-index/_bulk").with(
        body: payload,
        headers: {"Content-Type" => "application/json"}
    ).to_return(body: response)
    @wrapper.add [document]
    assert_requested(:post, "http://example.com:9200/test-index/_bulk")
  end

  def test_should_bulk_update_documents_with_id_field
    stub_popularity_index_requests(["/a/link"], 1.0)

    document = stub("document", elasticsearch_export: {
        "_type" => "not_an_edition",
        "_id" => "some_id",
        "title" => "TITLE ONE",
        "link" => "/a/link"
    })

    # Note that this comes with a trailing newline, which elasticsearch needs
    payload = <<-eos
{"index":{"_type":"not_an_edition","_id":"some_id"}}
{"_type":"not_an_edition","_id":"some_id","title":"TITLE ONE","link":"/a/link","popularity":1.0,"tags":[],"format":"not_an_edition"}
  eos
    response = <<-eos
{"took":5,"items":[
{ "index": { "_index":"test-index", "_type":"not_an_edition", "_id":"some_id", "ok":true } }
]}
    eos
    stub_request(:post, "http://example.com:9200/test-index/_bulk").with(
        body: payload,
        headers: {"Content-Type" => "application/json"}
    ).to_return(body: response)
    @wrapper.add [document]
    assert_requested(:post, "http://example.com:9200/test-index/_bulk")
  end

  def test_should_bulk_update_documents_with_raw_command_stream
    stub_popularity_index_requests(["/foo/bar"], 1.0)

    # Note that this comes with a trailing newline, which elasticsearch needs
    payload = <<-eos
{"index":{"_type":"edition","_id":"/foo/bar"}}
{"_type":"edition","link":"/foo/bar","title":"TITLE ONE","popularity":1.0,"tags":[],"format":"edition"}
    eos
    stub_request(:post, "http://example.com:9200/test-index/_bulk").with(
        body: payload,
        headers: {"Content-Type" => "application/json"}
    ).to_return(body: '{"items":[]}')
    @wrapper.bulk_index payload
    assert_requested(:post, "http://example.com:9200/test-index/_bulk")
  end

  def test_should_raise_error_for_failures_in_bulk_update
    stub_popularity_index_requests(["/foo/bar", "/foo/baz"], 1.0, 20)

    json_documents = [
      { "_type" => "edition", "link" => "/foo/bar", "title" => "TITLE ONE", "popularity" => "1.0" },
      { "_type" => "edition", "link" => "/foo/baz", "title" => "TITLE TWO", "popularity" => "1.0" }
    ]
    documents = json_documents.map do |json_document|
      stub("document", elasticsearch_export: json_document)
    end
    response = <<-eos
{"took":0,"items":[
  { "index": { "_index":"test-index", "_type":"edition", "_id":"/foo/bar", "ok":true } },
  { "index": { "_index":"test-index", "_type":"edition", "_id":"/foo/baz", "error":"stuff" } }
]}
    eos
    stub_request(:post, "http://example.com:9200/test-index/_bulk").to_return(body: response)

    begin
      @wrapper.add(documents)
      flunk("No exception raised")
    rescue Elasticsearch::BulkIndexFailure => e
      assert_equal "Failed inserts: /foo/baz", e.message
      assert_equal ["/foo/baz"], e.failed_keys
    end
  end

  def test_should_set_sensible_defaults_with_no_popularity_data
    # return no popularity data for this path
    stub_popularity_index_requests(["/foo/bar"], 0, 0, 10, [])

    # TODO: factor out with FactoryGirl
    json_document = {
        "_type" => "edition",
        "link" => "/foo/bar",
        "title" => "TITLE ONE",
    }
    document = stub("document", elasticsearch_export: json_document)

    # Note that this comes with a trailing newline, which elasticsearch needs
    payload = <<-eos
{"index":{"_type":"edition","_id":"/foo/bar"}}
{"_type":"edition","link":"/foo/bar","title":"TITLE ONE","popularity":0,"tags":[],"format":"edition"}
eos
    response = <<-eos
{"took":5,"items":[
{ "index": { "_index":"test-index", "_type":"edition", "_id":"/foo/bar", "ok":true } }
]}
eos

    request = stub_request(:post, "http://example.com:9200/test-index/_bulk")
                  .with(body: payload)
                  .to_return(body: response)
    @wrapper.add [document]

    assert_requested(request)
  end

  def test_should_populate_tags_field
    stub_popularity_index_requests(["/foo/bar"], 1.0)

    json_document = {
      "_type" => "edition",
      "link" => "/foo/bar",
      "specialist_sectors" => ["oil-and-gas/licensing", "oil-and-gas/onshore-oil-and-gas"],
      "organisations" => ["hm-magic"],
    }
    document = stub("document", elasticsearch_export: json_document)

    # Note that this comes with a trailing newline, which elasticsearch needs
    payload = <<-eos
{"index":{"_type":"edition","_id":"/foo/bar"}}
{"_type":"edition","link":"/foo/bar","specialist_sectors":["oil-and-gas/licensing","oil-and-gas/onshore-oil-and-gas"],"organisations":["hm-magic"],"popularity":1.0,"tags":["organisation:hm-magic","sector:oil-and-gas/licensing","sector:oil-and-gas/onshore-oil-and-gas"],"format":"edition"}
    eos
    response = <<-eos
{"took":5,"items":[
  { "index": { "_index":"test-index", "_type":"edition", "_id":"/foo/bar", "ok":true } }
]}
    eos
    stub_request(:post, "http://example.com:9200/test-index/_bulk").with(
        body: payload,
        headers: {"Content-Type" => "application/json"}
    ).to_return(body: response)
    @wrapper.add [document]
    assert_requested(:post, "http://example.com:9200/test-index/_bulk")
  end

  def test_should_populate_mainstream_browse_pages_field
    stub_popularity_index_requests(["/foo/bar"], 1.0)

    json_document = {
      "_type" => "edition",
      "link" => "/foo/bar",
      "section" => "benefits",
      "subsection" => "entitlement",
    }
    document = stub("document", elasticsearch_export: json_document)

    # Note that this comes with a trailing newline, which elasticsearch needs
    payload = <<-eos
{"index":{"_type":"edition","_id":"/foo/bar"}}
{"_type":"edition","link":"/foo/bar","section":"benefits","subsection":"entitlement","popularity":1.0,"mainstream_browse_pages":["benefits/entitlement"],"tags":[],"format":"edition"}
    eos
    response = <<-eos
{"took":5,"items":[
  { "index": { "_index":"test-index", "_type":"edition", "_id":"/foo/bar", "ok":true } }
]}
    eos

    bulk_request = stub_request(:post, "http://example.com:9200/test-index/_bulk").with(
        body: payload,
        headers: {"Content-Type" => "application/json"}
    ).to_return(body: response)

    @wrapper.add [document]

    assert_requested(bulk_request)
  end

  def test_should_allow_custom_timeouts_on_add
    stub_response = stub("response", body: '{"items": []}')
    RestClient::Request.expects(:execute)
      .with(has_entries(
        timeout: 20,
        open_timeout: 25
      )).returns(stub_response)

    # stub out popularity logic as we don't care about these for the purpose of
    # this unit test
    @wrapper.stubs(:lookup_popularities)

    @wrapper.add([], timeout: 20, open_timeout: 25)
  end

  def test_get_document
    document_url = "http://example.com:9200/test-index/edition/%2Fan-example-link"
    document_hash = {
      "_type" => "edition",
      "link" => "/an-example-link",
      "title" => "I am a title"
    }

    document_response = {
      "_index" => "test-index",
      "_type" => "edition",
      "_id" => "/an-example-link",
      "_version" => 4,
      "exists" => true,
      "_source" =>  document_hash
    }
    stub_request(:get, document_url).to_return(body: document_response.to_json)

    document = @wrapper.get("/an-example-link")
    assert document.is_a? Document
    assert_equal "/an-example-link", document.get(:link)
    assert_equal "/an-example-link", document.link
    assert_equal document_hash["title"], document.title
    assert_requested :get, document_url
  end

  def test_add_queued_documents
    json_document = {
        "_type" => "edition",
        "link" => "/foo/bar",
        "title" => "TITLE ONE",
    }
    document = stub("document", elasticsearch_export: json_document)

    mock_queue = mock("document queue") do
      expects(:queue_many).with([json_document])
    end
    Elasticsearch::IndexQueue.expects(:new)
      .with("test-index")
      .returns(mock_queue)

    @wrapper.add_queued([document])
  end

  def test_queued_delete
    mock_queue = mock("document queue") do
      expects(:queue_delete).with("edition", "/foobang")
    end
    Elasticsearch::IndexQueue.expects(:new)
      .with("test-index")
      .returns(mock_queue)

    @wrapper.delete_queued("edition", "/foobang")
  end

  def test_amend
    mock_document = mock("document") do
      expects(:has_field?).with("title").returns(true)
      expects(:set).with("title", "New title")
    end
    @wrapper.expects(:get).with("/foobang").returns(mock_document)
    @wrapper.expects(:add).with([mock_document])

    @wrapper.amend("/foobang", "title" => "New title")
  end

  def test_amend_with_link
    @wrapper.expects(:get).with("/foobang").returns(mock("document"))
    @wrapper.expects(:add).never

    assert_raises ArgumentError do
      @wrapper.amend("/foobang", "link" => "/flibble")
    end
  end

  def test_amend_with_bad_field
    mock_document = mock("document") do
      expects(:has_field?).with("fish").returns(false)
    end
    @wrapper.expects(:get).with("/foobang").returns(mock_document)
    @wrapper.expects(:add).never

    assert_raises ArgumentError do
      @wrapper.amend("/foobang", "fish" => "Trout")
    end
  end

  def test_amend_missing_document
    @wrapper.expects(:get).with("/foobang").returns(nil)
    @wrapper.expects(:add).never

    assert_raises Elasticsearch::DocumentNotFound do
      @wrapper.amend("/foobang", "title" => "New title")
    end
  end

  def test_get_document_not_found
    document_url = "http://example.com:9200/test-index/edition/%2Fa-bad-link"

    not_found_response = {
      "_index" => "rummager",
      "_type" => "edition",
      "_id" => "/a-bad-link",
      "exists" => false
    }.to_json

    stub_request(:get, document_url).to_return(
      status: 404,
      body: not_found_response
    )

    assert_nil @wrapper.get("/a-bad-link")
    assert_requested :get, document_url
  end

  def test_basic_keyword_search
    stub_request(:get, "http://example.com:9200/test-index/_search").with(
      body: %r{"query":"keyword search"},
      headers: {"Content-Type" => "application/json"}
    ).to_return(:body => '{"hits":{"hits":[]}}')
    @wrapper.search "keyword search"
    assert_requested(:get, "http://example.com:9200/test-index/_search")
  end

  def test_raises_error_for_invalid_query
    assert_raises Elasticsearch::InvalidQuery do
      @wrapper.search("keyword search", sort: "not_a_field_in_mappings")
    end
  end

  def test_raw_search
    stub_get = stub_request(:get, "http://example.com:9200/test-index/_search").with(
      body: %r{"query":"keyword search"},
      headers: {"Content-Type" => "application/json"}
    ).to_return(:body => '{"hits":{"hits":[]}}')
    @wrapper.raw_search({query: "keyword search"})
    assert_requested(stub_get)
  end

  def test_raw_search_with_type
    stub_get = stub_request(:get, "http://example.com:9200/test-index/test-type/_search").with(
      body: %r{"query":"keyword search"},
      headers: {"Content-Type" => "application/json"}
    ).to_return(:body => '{"hits":{"hits":[]}}')
    @wrapper.raw_search({query: "keyword search"}, "test-type")
    assert_requested(stub_get)
  end

  def test_commit
    refresh_url = "http://example.com:9200/test-index/_refresh"
    stub_request(:post, refresh_url).to_return(
      body: '{"ok":true,"_shards":{"total":1,"successful":1,"failed":0}}'
    )
    @wrapper.commit
    assert_requested :post, refresh_url
  end

  def test_can_fetch_documents_by_format
    search_pattern = "http://example.com:9200/test-index/_search?scroll=60m&search_type=scan&size=500"
    stub_request(:get, search_pattern).with(
      body: MultiJson.encode({query: {term: {format: "organisation"}}})
    ).to_return(
      body: MultiJson.encode({_scroll_id: "abcdefgh", hits: {total: 10}})
    )

    hits = (1..10).map { |i|
      { "_source" => { "link" => "/organisation-#{i}", "title" => "Organisation #{i}" } }
    }
    stub_request(:get, scroll_uri("abcdefgh")).to_return(
      body: scroll_response_body("abcdefgh", 10, hits)
    ).then.to_return(
      body: scroll_response_body("abcdefgh", 10, [])
    ).then.to_raise("should never happen")

    result = @wrapper.documents_by_format("organisation")
    assert_equal (1..10).map {|i| "Organisation #{i}" }, result.map(&:title)
  end

  def test_can_fetch_documents_by_format_with_certain_fields
    search_pattern = "http://example.com:9200/test-index/_search?scroll=60m&search_type=scan&size=500"
    query = {
      query: {term: {format: "organisation"}},
      fields: ["title", "link"]
    }
    stub_request(:get, search_pattern).with(
      body: MultiJson.encode(query)
    ).to_return(
      body: MultiJson.encode({_scroll_id: "abcdefgh", hits: {total: 10}})
    )

    hits = (1..10).map { |i|
      { "fields" => { "link" => "/organisation-#{i}", "title" => "Organisation #{i}" } }
    }
    stub_request(:get, scroll_uri("abcdefgh")).to_return(
      body: scroll_response_body("abcdefgh", 10, hits)
    ).then.to_return(
      body: scroll_response_body("abcdefgh", 10, [])
    ).then.to_raise("should never happen")

    result = @wrapper.documents_by_format("organisation", fields: %w(title link)).to_a
    assert_equal (1..10).map {|i| "Organisation #{i}" }, result.map(&:title)
    assert_equal (1..10).map {|i| "/organisation-#{i}" }, result.map(&:link)
  end

  def test_can_fetch_documents_by_format_with_fields_not_in_mappings
    # Notably, we want to be able to query for organisation acronyms before we
    # work out how best to add them to the mappings
    search_pattern = "http://example.com:9200/test-index/_search?scroll=60m&search_type=scan&size=500"
    query = {
      query: {term: {format: "organisation"}},
      fields: ["title", "link", "wumpus"]
    }
    stub_request(:get, search_pattern).with(
      body: MultiJson.encode(query)
    ).to_return(
      body: MultiJson.encode({_scroll_id: "abcdefgh", hits: {total: 10}})
    )

    hits = [
      { "fields" => { "link" => "/org", "title" => "Org", "wumpus" => "totes" } }
    ]
    stub_request(:get, scroll_uri("abcdefgh")).to_return(
      body: scroll_response_body("abcdefgh", 1, hits)
    ).then.to_return(
      body: scroll_response_body("abcdefgh", 10, [])
    ).then.to_raise("should never happen")

    result = @wrapper.documents_by_format("organisation", fields: %w(title link wumpus)).to_a
    first = result[0]
    assert_equal "totes", first.wumpus
  end

  def test_all_documents_size
    # Test that we can count the documents without retrieving them all
    search_pattern = "http://example.com:9200/test-index/_search?scroll=60m&search_type=scan&size=50"
    stub_request(:get, search_pattern).with(
      body: MultiJson.encode({query: {match_all: {}}})
    ).to_return(
      body: MultiJson.encode({_scroll_id: "abcdefgh", hits: {total: 100}})
    ).then.to_raise("should never happen")
    assert_equal @wrapper.all_documents.size, 100
  end

  def test_all_documents
    search_uri = "http://example.com:9200/test-index/_search?scroll=60m&search_type=scan&size=50"

    stub_request(:get, search_uri).with(
      body: MultiJson.encode({query: {match_all: {}}})
    ).to_return(
      body: MultiJson.encode({_scroll_id: "abcdefgh", hits: {total: 100}})
    )
    hits = (1..100).map { |i|
      { "_source" => { "link" => "/foo-#{i}" } }
    }
    stub_request(:get, scroll_uri("abcdefgh")).to_return(
      body: scroll_response_body("abcdefgh", 100, hits[0, 50])
    ).then.to_return(
      body: scroll_response_body("abcdefgh", 100, hits[50, 50])
    ).then.to_return(
      body: scroll_response_body("abcdefgh", 100, [])
    ).then.to_raise("should never happen")
    all_documents = @wrapper.all_documents.to_a
    assert_equal 100, all_documents.size
    assert_equal "/foo-1", all_documents.first.link
    assert_equal "/foo-100", all_documents.last.link
  end

  def test_changing_scroll_id
    search_uri = "http://example.com:9200/test-index/_search?scroll=60m&search_type=scan&size=2"

    Elasticsearch::Index.stubs(:scroll_batch_size).returns(2)

    stub_request(:get, search_uri).with(
      body: MultiJson.encode({query: {match_all: {}}})
    ).to_return(
      body: MultiJson.encode({_scroll_id: "abcdefgh", hits: {total: 3}})
    )
    hits = (1..3).map { |i|
      { "_source" => { "link" => "/foo-#{i}" } }
    }
    total = hits.size

    stub_request(:get, scroll_uri("abcdefgh")).to_return(
      body: scroll_response_body("ijklmnop", total, hits[0, 2])
    ).then.to_raise("should never happen")

    stub_request(:get, scroll_uri("ijklmnop")).to_return(
      body: scroll_response_body("qrstuvwx", total, hits[2, 1])
    ).then.to_raise("should never happen")

    stub_request(:get, scroll_uri("qrstuvwx")).to_return(
      body: scroll_response_body("yz", total, [])
    ).then.to_raise("should never happen")

    all_documents = @wrapper.all_documents.to_a
    assert_equal ["/foo-1", "/foo-2", "/foo-3"], all_documents.map(&:link)
  end

  def test_should_allow_custom_timeouts_on_iteration
    RestClient::Request.expects(:execute)
      .with(has_entries(
        timeout: 20,
        open_timeout: 25
      )).returns('{"hits": {"total": 0}}')
    @wrapper.all_documents(timeout: 20, open_timeout: 25)
  end

  def test_should_specify_longer_timeouts_on_population
    timeout_params = {
      timeout: Elasticsearch::Index::LONG_TIMEOUT_SECONDS,
      open_timeout: Elasticsearch::Index::LONG_OPEN_TIMEOUT_SECONDS
    }
    stub_doc = stub("document")
    old_index = mock("old index")
    old_index.stubs(:index_name).returns("Old index")
    old_index.expects(:all_documents).with(has_entries(timeout_params)).returns([stub_doc])
    @wrapper.expects(:add).with([stub_doc], has_entries(timeout_params))
    @wrapper.expects(:commit).at_most_once  # Not central to this test

    @wrapper.populate_from(old_index)
  end

  def scroll_uri(scroll_id)
     "http://example.com:9200/_search/scroll?scroll=60m&scroll_id=#{scroll_id}"
  end

  def scroll_response_body(scroll_id, total_results, results)
      MultiJson.encode(
        {
          _scroll_id: scroll_id,
          hits: {total: total_results, hits: results}
        }
      )
  end
end
