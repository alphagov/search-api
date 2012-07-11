require 'test_helper'
require 'solr_wrapper'

class SolrWrapper::CompleteTest < Test::Unit::TestCase
  def setup
    @client = mock("client")
    @wrapper = SolrWrapper.new(@client, nil)
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
end
