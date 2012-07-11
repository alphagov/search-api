require 'test_helper'
require 'solr_wrapper'

class SolrWrapper::CompleteTest < Test::Unit::TestCase
  def setup
    @client = mock("client")
    @recommended_format = 'recommended-format'
    @wrapper = SolrWrapper.new(@client, @recommended_format)
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

  def test_should_allow_autocompletion_to_be_filtered_by_the_specified_format
    @client.expects(:query).with("standard", has_entry(fq: "format:foobar"))
    @wrapper.complete("", "foobar")
  end

  def test_should_escape_the_filter_option
    @client.expects(:query).with("standard", has_entry(fq: "format:\\*"))
    @wrapper.complete("", "*")
  end

  def test_should_pass_the_default_fq_parameter_if_no_format_is_specified
    @client.expects(:query).with("standard", has_entry(fq: "-format:#{@recommended_format}"))
    @wrapper.complete("")
  end
end
