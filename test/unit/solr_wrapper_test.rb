require "test_helper"
require "solr_wrapper"

class SolrWrapperTest < Test::Unit::TestCase
  def test_should_update_solr_client_with_exported_document
    solr_document = stub("solr document", xml: "<EXPORTED/>")
    document = stub("document", solr_export: solr_document)
    client = mock("client")
    wrapper = SolrWrapper.new(client)

    client.expects(:update!).with(solr_document, anything)
    wrapper.add document
  end

  def test_should_tell_solr_to_commit_within_five_minutes
    solr_document = stub("solr document", xml: "<EXPORTED/>")
    document = stub("document", solr_export: solr_document)
    client = mock("client")
    wrapper = SolrWrapper.new(client)

    client.expects(:update!).with(anything, has_entry(commitWithin: 5*60*1000))
    wrapper.add document
  end
end
