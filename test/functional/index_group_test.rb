require "test_helper"
require "multi_json"
require "elasticsearch/search_server"
require "elasticsearch/index_group"

class IndexGroupTest < MiniTest::Unit::TestCase

  ELASTICSEARCH_OK = {
    status: 200,
    body: MultiJson.encode({"ok" => true, "acknowledged" => true})
  }

  def setup
    @schema = {
      "index" => {
        "settings" => "awesomeness"
      },
      "mappings" => {
        "default" => {
          "edition" => {
            "properties" => {
              "title" => { "type" => "string" }
            }
          }
        },
        "custom" => {
          "edition" => {
            "properties" => {
              "title" => { "type" => "string" },
              "description" => { "type" => "string" }
            }
          }
        }
      }
    }
    @server = Elasticsearch::SearchServer.new(
      "http://localhost:9200/",
      @schema,
      ["mainstream", "custom"]
    )
  end

  def test_create_index
    expected_body = MultiJson.encode({
      "settings" => @schema["index"]["settings"],
      "mappings" => @schema["mappings"]["default"]
    })
    stub = stub_request(:put, %r(http://localhost:9200/mainstream-.*/))
      .with(body: expected_body)
      .to_return(
        status: 200,
        body: '{"ok": true, "acknowledged": true}'
      )
    index = @server.index_group("mainstream").create_index

    assert_requested(stub)
    assert index.is_a? Elasticsearch::Index
    assert_match(/^mainstream-/, index.index_name)
    assert_equal ["title"], index.field_names
  end

  def test_create_index_with_custom_mappings
    expected_body = MultiJson.encode({
      "settings" => @schema["index"]["settings"],
      "mappings" => @schema["mappings"]["custom"]
    })
    stub = stub_request(:put, %r(http://localhost:9200/custom-.*/))
      .with(body: expected_body)
      .to_return(
        status: 200,
        body: '{"ok": true, "acknowledged": true}'
      )
    index = @server.index_group("custom").create_index

    assert_requested(stub)
    assert index.is_a? Elasticsearch::Index
    assert_match(/^custom-/, index.index_name)
    assert_equal ["title", "description"], index.field_names
  end

  def test_switch_index_with_no_existing_alias
    new_index = stub("New index", index_name: "test-new")
    get_stub = stub_request(:get, "http://localhost:9200/_aliases")
      .to_return(
        status: 200,
        body: MultiJson.encode({
          "test-new" => { "aliases" => {} }
        })
      )
    expected_body = MultiJson.encode({
      "actions" => [
        { "add" => { "index" => "test-new", "alias" => "test" } }
      ]
    })
    post_stub = stub_request(:post, "http://localhost:9200/_aliases")
      .with(body: expected_body)
      .to_return(ELASTICSEARCH_OK)

    @server.index_group("test").switch_to(new_index)

    assert_requested(get_stub)
    assert_requested(post_stub)
  end

  def test_switch_index_with_existing_alias
    new_index = stub("New index", index_name: "test-new")
    get_stub = stub_request(:get, "http://localhost:9200/_aliases")
      .to_return(
        status: 200,
        body: MultiJson.encode({
          "test-old" => { "aliases" => { "test" => {} } },
          "test-new" => { "aliases" => {} }
        })
      )

    expected_body = MultiJson.encode({
      "actions" => [
        { "remove" => { "index" => "test-old", "alias" => "test" } },
        { "add" => { "index" => "test-new", "alias" => "test" } }
      ]
    })
    post_stub = stub_request(:post, "http://localhost:9200/_aliases")
      .with(body: expected_body)
      .to_return(ELASTICSEARCH_OK)

    @server.index_group("test").switch_to(new_index)

    assert_requested(get_stub)
    assert_requested(post_stub)
  end

  def test_switch_index_with_multiple_existing_aliases
    # Not expecting the system to get into this state, but it should cope
    new_index = stub("New index", index_name: "test-new")
    get_stub = stub_request(:get, "http://localhost:9200/_aliases")
      .to_return(
        status: 200,
        body: MultiJson.encode({
          "test-old" => { "aliases" => { "test" => {} } },
          "test-old2" => { "aliases" => { "test" => {} } },
          "test-new" => { "aliases" => {} }
        })
      )

    expected_body = MultiJson.encode({
      "actions" => [
        { "remove" => { "index" => "test-old", "alias" => "test" } },
        { "remove" => { "index" => "test-old2", "alias" => "test" } },
        { "add" => { "index" => "test-new", "alias" => "test" } }
      ]
    })
    post_stub = stub_request(:post, "http://localhost:9200/_aliases")
      .with(body: expected_body)
      .to_return(ELASTICSEARCH_OK)

    @server.index_group("test").switch_to(new_index)

    assert_requested(get_stub)
    assert_requested(post_stub)
  end

  def test_switch_index_with_existing_real_index
    new_index = stub("New index", index_name: "test-new")
    get_stub = stub_request(:get, "http://localhost:9200/_aliases")
      .to_return(
        status: 200,
        body: MultiJson.encode({
          "test" => { "aliases" => {} }
        })
      )

    assert_raises RuntimeError do
      @server.index_group("test").switch_to(new_index)
    end
  end
end
