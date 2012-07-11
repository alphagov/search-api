require 'test_helper'
require 'solr_wrapper'

class SolrWrapper::SearchTest < Test::Unit::TestCase
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
