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

  def test_should_return_an_empty_array_if_query_returns_nil
    client = stub("client")
    wrapper = SolrWrapper.new(client)
    client.stubs(:query).returns(nil)
    assert_equal [], wrapper.search("foo")
  end

  def test_should_return_an_array_of_documents_for_search_results
    client = stub("client")
    wrapper = SolrWrapper.new(client)
    result = stub(docs: [{
      "title" => "TITLE1",
      "description" => "DESCRIPTION",
      "format" => "local_transaction",
      "link" => "/URL"
    }])
    client.stubs(:query).returns(result)
    docs = wrapper.search("foo")

    assert_equal 1, docs.length
    assert_equal "TITLE1", docs.first.title
    assert_equal "DESCRIPTION", docs.first.description
    assert_equal "local_transaction", docs.first.format
    assert_equal "/URL", docs.first.link
  end

  def test_should_use_standard_search_handler
    client = mock("client")
    wrapper = SolrWrapper.new(client)
    client.expects(:query).with("standard", anything)
    wrapper.search("foo")
  end

  def test_should_ask_solr_for_search_term
    client = mock("client")
    wrapper = SolrWrapper.new(client)
    client.expects(:query).with(anything, has_entry(query: "foo"))
    wrapper.search("foo")
  end

  def test_should_ask_solr_for_all_fields_in_results
    client = mock("client")
    wrapper = SolrWrapper.new(client)
    client.expects(:query).with(anything, has_entry(fields: "*"))
    wrapper.search("foo")
  end
end
