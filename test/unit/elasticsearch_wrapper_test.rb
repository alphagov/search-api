require "test_helper"
require "elasticsearch_wrapper"
require "webmock"

class ElasticsearchWrapperTest < Test::Unit::TestCase
  def setup
    @settings = {
      server: "example.com",
      port: 9200,
      index_name: "test-index"
    }
    @wrapper = ElasticsearchWrapper.new(@settings, "myformat")
  end

  def test_should_bulk_update_documents
    # TODO: factor out with FactoryGirl
    json_document = {
        _type: "edition",
        link: "/foo/bar",
        title: "TITLE ONE",
    }
    document = stub("document", elasticsearch_export: json_document)
    # Note that this comes with a trailing newline, which elasticsearch needs
    payload = <<-eos
{"index":{"_type":"edition","_id":"/foo/bar"}}
{"_type":"edition","link":"/foo/bar","title":"TITLE ONE"}
    eos
    stub_request(:post, "http://example.com:9200/test-index/_bulk").with(
        body: payload,
        headers: {"Content-Type" => "application/json"}
    )
    @wrapper.add [document]
    assert_requested(:post, "http://example.com:9200/test-index/_bulk")
  end

  def test_basic_keyword_search
    stub_request(:get, "http://example.com:9200/test-index/_search").with(
        body: {
            from: 0, size: 50,
            query: {
                bool: {
                    must: {
                        query_string: {
                            fields: %w(title description indexable_content),
                            query: "keyword search"
                        }
                    },
                    should: {
                        query_string: {
                            default_field: "format",
                            query: "transaction OR myformat",
                            boost: 3.0
                        }
                    }
                }
            },
            highlight: {
                pre_tags: %w(HIGHLIGHT_START),
                post_tags: %w(HIGHLIGHT_END),
                fields: {
                    description: {},
                    indexable_content: {}
                }
            }
        }.to_json,
        headers: {"Content-Type" => "application/json"}
    ).to_return(:body => '{"hits":{"hits":[]}}')
    @wrapper.search "keyword search"
    assert_requested(:get, "http://example.com:9200/test-index/_search")
  end
end
