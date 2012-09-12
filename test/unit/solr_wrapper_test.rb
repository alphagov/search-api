require "test_helper"
require "solr_wrapper"

class SolrWrapperTest < Test::Unit::TestCase

  def sample_document
    {
      "title" => "TITLE1",
      "description" => "DESCRIPTION",
      "format" => "local_transaction",
      "link" => "/URL"
    }
  end

  def setup
    @client = mock("client")
    @wrapper = SolrWrapper.new(@client, nil)
  end

  def test_should_update_solr_client_with_exported_document
    solr_document = stub("solr document", xml: "<EXPORTED/>")
    document = stub("document", solr_export: solr_document)
    @client.expects(:update!).with([solr_document], anything)
    @wrapper.add [document]
  end

  def test_should_tell_solr_to_commit_within_five_minutes
    solr_document = stub("solr document", xml: "<EXPORTED/>")
    document = stub("document", solr_export: solr_document)
    @client.expects(:update!).with(anything, has_entry(commitWithin: 5*60*1000))
    @wrapper.add [document]
  end

  def test_facet_doesnt_return_blanks
    result = stub(facet_field_values: ["rod", "", "jane", "freddy", ""])
    @client.stubs(:query).returns(result)
    facets = @wrapper.facet("foo")

    assert_equal 3, facets.length
  end

  def test_facet_should_ask_for_everything
    @client.expects(:query).with("standard", has_entries(query: "*:*"))
    @wrapper.facet("foo")
  end

  def test_facet_should_ask_for_and_sort_by_specified_facet
    @client.expects(:query).with("standard", has_entries(facets: [{:field => "foo", :sort => "foo"}]))
    @wrapper.facet("foo")
  end

  def test_should_escape_characters_with_special_meaning_in_solr
    input = '+ - && || ! ( ) { } [ ] ^ " ~ * ? : \\'
    expected = '\\+ \\- \\&& \\|| \\! \\( \\) \\{ \\} \\[ \\] \\^ \\" \\~ \\* \\? \\: \\\\'
    assert_equal expected, @wrapper.escape(input)
  end

  def test_should_get_single_document
    result = stub(
      docs: [sample_document],
      raw_response: true,
      highlights_for: nil
    )
    @client.expects(:query).
      with("standard", has_entries(query: "link:/foobang", limit: 1)).
      returns(result)

    assert_equal sample_document["link"], @wrapper.get("/foobang").link
  end

  def test_get_should_return_no_result
    @client.expects(:query).
      with("standard", has_entries(query: "link:/foobang", limit: 1)).
      returns(stub(docs: [], raw_response: true, highlights_for: nil))
    assert_nil @wrapper.get("/foobang")
  end

  def test_get_should_escape_query
    result = stub(
      docs: [sample_document],
      raw_response: true,
      highlights_for: nil
    )
    @client.expects(:query).
      with("standard", has_entries(query: "link:\\\\foobang\\(", limit: 1)).
      returns(result)
    @wrapper.get("\\foobang(")
  end

  def test_should_delete_by_escaped_link
    @client.expects(:delete_by_query).with("link:foo\\-bar")
    @wrapper.delete("foo-bar")
  end

  def test_should_delete_all
    @client.expects(:delete_by_query).with("link:[* TO *]")
    @client.expects(:commit!)
    @client.expects(:optimize!)
    @wrapper.delete_all
  end
end