require "test_helper"
require "multi_json"
require "elasticsearch/search_server"
require "elasticsearch/index_group"

class IndexGroupTest < MiniTest::Unit::TestCase

  def setup
    @server = Elasticsearch::SearchServer.new(
      "http://localhost:9200/",
      {
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
    )
  end

  def test_create_index
    expected_body = MultiJson.encode({
      "settings" => "awesomeness",
      "mappings" => {
        "edition" => {
          "properties" => {
            "title" => { "type" => "string" }
          }
        }
      }
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
    assert_match(/^mainstream-/, index.name)
    assert_equal ["title"], index.field_names
  end

  def test_create_index_with_custom_mappings
    expected_body = MultiJson.encode({
      "settings" => "awesomeness",
      "mappings" => {
        "edition" => {
          "properties" => {
            "title" => { "type" => "string" },
            "description" => { "type" => "string" }
          }
        }
      }
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
    assert_match(/^custom-/, index.name)
    assert_equal ["title", "description"], index.field_names
  end
end
