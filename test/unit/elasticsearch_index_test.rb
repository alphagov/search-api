require "test_helper"
require "elasticsearch/index"
require "webmock"

class ElasticsearchIndexTest < MiniTest::Unit::TestCase
  include Fixtures::DefaultMappings

  def setup
    base_uri = URI.parse("http://example.com:9200")
    @wrapper = Elasticsearch::Index.new(base_uri, "test-index", default_mappings)
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
    # elasticsearch is weird: even though /index/_status 404s if the index
    # doesn't exist, /index/_aliases returns a 200.
    stub_request(:get, "http://example.com:9200/test-index/_aliases")
      .to_return(
        status: 200,
        body: "{}",
        headers: {"Content-Type" => "application/json"}
      )

    refute @wrapper.exists?
  end

  def test_should_bulk_update_documents
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
{"_type":"edition","link":"/foo/bar","title":"TITLE ONE"}
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

  def test_should_raise_error_for_failures_in_bulk_update
    json_documents = [
      { "_type" => "edition", "link" => "/foo/bar", "title" => "TITLE ONE" },
      { "_type" => "edition", "link" => "/foo/baz", "title" => "TITLE TWO" }
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

  def test_get_document
    document_url = "http://example.com:9200/test-index/_all/%2Fan-example-link"
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
      expects(:queue_delete).with("/foobang")
    end
    Elasticsearch::IndexQueue.expects(:new)
      .with("test-index")
      .returns(mock_queue)

    @wrapper.delete_queued("/foobang")
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
    document_url = "http://example.com:9200/test-index/_all/%2Fa-bad-link"

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

  def test_commit
    refresh_url = "http://example.com:9200/test-index/_refresh"
    stub_request(:post, refresh_url).to_return(
      body: '{"ok":true,"_shards":{"total":1,"successful":1,"failed":0}}'
    )
    @wrapper.commit
    assert_requested :post, refresh_url
  end

  def test_can_fetch_documents_by_format
    search_pattern = "http://example.com:9200/test-index/_search?scroll=1m&search_type=scan&size=500"
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
    search_pattern = "http://example.com:9200/test-index/_search?scroll=1m&search_type=scan&size=500"
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
    search_pattern = "http://example.com:9200/test-index/_search?scroll=1m&search_type=scan&size=500"
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
    search_pattern = "http://example.com:9200/test-index/_search?scroll=1m&search_type=scan&size=50"
    stub_request(:get, search_pattern).with(
      body: MultiJson.encode({query: {match_all: {}}})
    ).to_return(
      body: MultiJson.encode({_scroll_id: "abcdefgh", hits: {total: 100}})
    ).then.to_raise("should never happen")
    assert_equal @wrapper.all_documents.size, 100
  end

  def test_all_documents
    search_uri = "http://example.com:9200/test-index/_search?scroll=1m&search_type=scan&size=50"

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
    search_uri = "http://example.com:9200/test-index/_search?scroll=1m&search_type=scan&size=2"

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

  def scroll_uri(scroll_id)
     "http://example.com:9200/_search/scroll?scroll=1m&scroll_id=#{scroll_id}"
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
