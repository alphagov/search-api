require "test_helper"
require "elasticsearch_wrapper"
require "webmock"

class ElasticsearchWrapperTest < Test::Unit::TestCase
  def setup
    @settings = {
        "baseurl" => "http://example.com:9200/",
        "indexname" => "test-index"
    }
    @wrapper = ElasticsearchWrapper.new(@settings, nil)
  end

  def test_should_bulk_update_documents
    # TODO: factor out with FactoryGirl
    json_document = {
        _type: "edition",
        link: "/foo/bar",
        title: "TITLE ONE",
    }
    document = stub("document", elasticsearch_export: json_document)
    payload = <<-eos
{"index":{"_index":"test-index","_type":"edition","_id":"/foo/bar"}}
{"_type":"edition","link":"/foo/bar","title":"TITLE ONE"}
    eos
    stub_request(:post, "http://example.com:9200/test-index/_bulk").with(
        body: payload.strip,
        headers: {"Content-Type" => "application/json"}
    )
    @wrapper.add [document]
  end
end