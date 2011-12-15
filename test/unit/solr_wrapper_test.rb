require "test_helper"
require "solr_wrapper"

class SolrWrapperTest < Test::Unit::TestCase
  def test_should_update_solr_client_with_exported_document
    solr_document = stub("solr document", xml: "<EXPORTED/>")
    document = stub("document", solr_export: solr_document)
    client = mock("client")
    wrapper = SolrWrapper.new(client)

    client.expects(:update!).with([solr_document], anything)
    wrapper.add [document]
  end

  def test_should_tell_solr_to_commit_within_five_minutes
    solr_document = stub("solr document", xml: "<EXPORTED/>")
    document = stub("document", solr_export: solr_document)
    client = mock("client")
    wrapper = SolrWrapper.new(client)

    client.expects(:update!).with(anything, has_entry(commitWithin: 5*60*1000))
    wrapper.add [document]
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

  def test_facet_doesnt_return_blanks
    client = stub("client")
    wrapper = SolrWrapper.new(client)
    result = stub(facet_field_values: ["rod", "", "jane", "freddy", ""])
    client.stubs(:query).returns(result)
    facets = wrapper.facet("foo")

    assert_equal 3, facets.length
  end

  def test_should_use_dismax_search_handler
    client = mock("client")
    wrapper = SolrWrapper.new(client)
    client.expects(:query).with("dismax", anything)
    wrapper.search("foo")
  end

  def test_should_ask_solr_for_search_term
    client = mock("client")
    wrapper = SolrWrapper.new(client)
    client.expects(:query).with(anything, has_entry(query: "foo"))
    wrapper.search("foo")
  end

  def test_should_escape_search_term
    client = mock("client")
    wrapper = SolrWrapper.new(client)
    client.expects(:query).with(anything, has_entry(query: "foo\\?"))
    wrapper.search("foo?")
  end

  def test_should_downcase_search_term
    client = mock("client")
    wrapper = SolrWrapper.new(client)
    client.expects(:query).with("dismax", has_entry(query: "foo"))
    wrapper.search("FOO")
  end

  def test_should_ask_solr_for_all_fields_in_results
    client = mock("client")
    wrapper = SolrWrapper.new(client)
    client.expects(:query).with(anything, has_entry(fields: "*"))
    wrapper.search("foo")
  end

  def test_should_prioritise_recommended_links
    client = mock("client")
    wrapper = SolrWrapper.new(client)
    client.expects(:query).with(anything, has_entry(bq: "format:recommended-link"))
    wrapper.search("foo")
  end

  def test_facet_should_ask_for_everything
    client = mock("client")
    wrapper = SolrWrapper.new(client)
    client.expects(:query).with("standard", has_entries(query: "*:*"))
    wrapper.facet("foo")
  end

  def test_facet_should_ask_for_and_sort_by_specified_facet
    client = mock("client")
    wrapper = SolrWrapper.new(client)
    client.expects(:query).with("standard", has_entries(facets: [{:field => "foo", :sort => "foo"}]))
    wrapper.facet("foo")
  end

  def test_should_ask_solr_for_partial_autocomplete_field
    client = mock("client")
    wrapper = SolrWrapper.new(client)
    client.expects(:query).with("dismax", has_entries(fields: "*", query: "autocomplete:foo*"))
    wrapper.complete("foo")
  end

  def test_should_escape_autocomplete_term
    client = mock("client")
    wrapper = SolrWrapper.new(client)
    client.expects(:query).with("dismax", has_entry(query: "autocomplete:foo\\?*"))
    wrapper.complete("foo?")
  end

  def test_should_downcase_autocomplete_term
    client = mock("client")
    wrapper = SolrWrapper.new(client)
    client.expects(:query).with("dismax", has_entry(query: "autocomplete:foo*"))
    wrapper.complete("FOO")
  end

  def test_should_escape_characters_with_special_meaning_in_solr
    client = mock("client")
    wrapper = SolrWrapper.new(client)
    input = '+ - && || ! ( ) { } [ ] ^ " ~ * ? : \\'
    expected = '\\+ \\- \\&& \\|| \\! \\( \\) \\{ \\} \\[ \\] \\^ \\" \\~ \\* \\? \\: \\\\'
    assert_equal expected, wrapper.escape(input)
  end

  def test_should_delete_by_escaped_link
    client = mock("client")
    wrapper = SolrWrapper.new(client)
    client.expects(:delete_by_query).with("link:foo\\-bar")
    wrapper.delete("foo-bar")
  end
end
