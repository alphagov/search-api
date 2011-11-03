require "test_helper"
require "solr_wrapper"

class SolrWrapperTest < Test::Unit::TestCase
  def test_should_update_solr_client_with_exported_document
    document = mock("document")
    document.stubs(:solr_export).returns("<EXPORTED/>")
    client = mock("client")
    wrapper = SolrWrapper.new(client)

    client.expects(:update!).with("<EXPORTED/>")
    wrapper.add document
  end
end
