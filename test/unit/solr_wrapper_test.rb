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

  def test_should_return_an_empty_array_if_query_returns_nil
    @client.stubs(:query).returns(nil)
    assert_equal [], @wrapper.search("foo")
  end

  def test_should_return_an_array_of_documents_for_search_results
    result = stub(docs: [sample_document],
      raw_response: true,
      highlights_for: nil
    )
    @client.stubs(:query).returns(result)
    docs = @wrapper.search("foo")

    assert_equal 1, docs.length
    assert_equal "TITLE1", docs.first.title
    assert_equal "DESCRIPTION", docs.first.description
    assert_equal "local_transaction", docs.first.format
    assert_equal "/URL", docs.first.link
  end

  def test_should_ask_for_highlight
    @client.expects(:query).with(anything, has_entries(
      :hl => "true",
      "hl.simple.pre"  => "HIGHLIGHT_START",
      "hl.simple.post" => "HIGHLIGHT_END",
    ))
    @wrapper.search("foo")
  end

  def test_should_use_highlighted_description_first
    result = stub(
      docs: [
        { "title" => "TITLE1", "description" => "DESCRIPTION1",
          "format" => "local_transaction", "link" => "/URL1" },
      ],
      raw_response: true
    )
    result.stubs(:highlights_for).with("/URL1", "description").
      returns(["DESC_HL1"])
    result.stubs(:highlights_for).with("/URL1", "indexable_content").
      returns(["IC_HL1"])
    @client.stubs(:query).returns(result)
    docs = @wrapper.search("foo")

    assert_equal "DESC_HL1", docs.first.highlight
  end

  def test_should_use_highlighted_indexable_content_second
    result = stub(
      docs: [
        { "title" => "TITLE1", "description" => "DESCRIPTION1",
          "format" => "local_transaction", "link" => "/URL1" },
      ],
      raw_response: true
    )
    result.stubs(:highlights_for).with("/URL1", "description").
      returns(nil)
    result.stubs(:highlights_for).with("/URL1", "indexable_content").
      returns(["IC_HL1"])
    @client.stubs(:query).returns(result)
    docs = @wrapper.search("foo")

    assert_equal "IC_HL1", docs.first.highlight
  end

  def test_should_use_description_if_not_highlight_is_available
    result = stub(
      docs: [
        { "title" => "TITLE1", "description" => "DESCRIPTION1",
          "format" => "local_transaction", "link" => "/URL1" },
      ],
      raw_response: true,
      highlights_for: nil
    )
    @client.stubs(:query).returns(result)
    docs = @wrapper.search("foo")

    assert_equal "DESCRIPTION1", docs.first.highlight
  end

  def test_should_return_zero_if_no_raw_response_returned
    result = stub(raw_response: nil)
    @client.stubs(:query).returns(result)
    docs = @wrapper.search("foo")

    assert_equal 0, docs.length
  end

  def test_facet_doesnt_return_blanks
    result = stub(facet_field_values: ["rod", "", "jane", "freddy", ""])
    @client.stubs(:query).returns(result)
    facets = @wrapper.facet("foo")

    assert_equal 3, facets.length
  end

  def test_should_use_dismax_search_handler_for_search
    @client.expects(:query).with("dismax", anything)
    @wrapper.search("foo")
  end

  def test_should_ask_solr_for_search_term_with_trailing_wildcard
    @client.expects(:query).with(anything, has_entry(query: 'foo*'))
    @wrapper.search("foo")
  end

  def test_should_escape_search_term
    @client.expects(:query).with(anything, has_entry(query: "foo\\?*"))
    @wrapper.search("foo?")
  end

  def test_should_downcase_search_term
    @client.expects(:query).with(anything, has_entry(query: 'foo*'))
    @wrapper.search("FOO")
  end

  def test_should_ask_solr_for_relevant_fields_in_results
    @client.expects(:query).with(anything, has_entry(fields: "title,link,description,format,section,additional_links__title,additional_links__link,additional_links__link_order"))
    @wrapper.search("foo")
  end

  def test_should_prioritise_recommended_links_and_transactions
    wrapper = SolrWrapper.new(@client, "recommended-link")
    @client.expects(:query).with(anything, has_entry(bq: "format:(transaction OR recommended-link)^3.0"))
    wrapper.search("foo")
  end

  def test_facet_should_ask_for_everything
    @client.expects(:query).with("standard", has_entries(query: "*:*"))
    @wrapper.facet("foo")
  end

  def test_facet_should_ask_for_and_sort_by_specified_facet
    @client.expects(:query).with("standard", has_entries(facets: [{:field => "foo", :sort => "foo"}]))
    @wrapper.facet("foo")
  end

  def test_should_ask_solr_for_partial_autocomplete_field
    @client.expects(:query).with("standard", has_entries(fields: "title,link,format", query: "autocomplete:foo*"))
    @wrapper.complete("foo")
  end

  def test_should_escape_autocomplete_term
    @client.expects(:query).with("standard", has_entry(query: "autocomplete:foo\\?*"))
    @wrapper.complete("foo?")
  end

  def test_should_downcase_autocomplete_term
    @client.expects(:query).with("standard", has_entry(query: "autocomplete:foo*"))
    @wrapper.complete("FOO")
  end

  def test_should_autocomplete_words_separately
    @client.expects(:query).with("standard", has_entry(query: "autocomplete:foo* autocomplete:bar*"))
    @wrapper.complete("foo bar")
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

  def test_should_limit_minimum_field_match_to_75_percent
    @client.expects(:query).with(anything, has_entry(mm: "75%"))
    @wrapper.search("foo")
  end

  def test_should_allow_the_query_to_be_filtered_by_the_specified_format
    @client.expects(:query).with(anything, has_entry(fq: "format:foobar"))
    @wrapper.search("", "foobar")
  end

  def test_should_escape_the_filter_option
    @client.expects(:query).with(anything, has_entry(fq: "format:\\*"))
    @wrapper.search("", "*")
  end

  def test_should_not_pass_the_fq_parameter_unless_a_format_is_specified
    @client.expects(:query).with(anything, Not(has_key(:fq)))
    @wrapper.search("")
  end
end
