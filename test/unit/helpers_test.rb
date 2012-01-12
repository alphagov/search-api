# encoding: utf-8
require "test_helper"
require "app"

class HelperTest < Test::Unit::TestCase
  def app
    Sinatra::Application
  end

  def h
    HelperAccessor.new
  end

  def test_formatting_format_name
    assert_equal "Tests", h.formatted_format_name("test")
  end

  def test_formatting_format_name_with_replacement
    app.settings.stubs(:format_name_alternatives).returns({"clark kent" => "superman"})
    assert_equal "superman", h.formatted_format_name("clark kent")
  end

  def test_include_throws_no_error_on_non_existent_file
    assert_equal nil, h.include("really_doesnt_exist.html")
  end

  def test_sort_documents_by_index_with_empty_list
    docs = []
    index = []
    assert_equal [], sort_documents_by_index(docs, index)
  end

  def sample_document_list
    doc1 = Document.from_hash({
      "title" => "TITLE",
      "format" => "two",
    })
    doc2 = Document.from_hash({
      "title" => "TITLE",
      "format" => "one",
    })
    [doc1, doc2]
  end

  def test_sort_documents_by_index_with_no_index
    index = []
    docs = sample_document_list
    sorted = sort_documents_by_index(docs, index)
    assert_equal 2, sorted.count
  end

  def test_sort_documents_by_index_with_index
    docs = sample_document_list
    sorted = sort_documents_by_index(docs, ["one", "two"])
    assert_equal "one", sorted.first[0]

    sorted = sort_documents_by_index(docs, ["two", "one"])
    assert_equal "two", sorted.first[0]
  end

  def test_sort_documents_by_index_with_incomplete_index
    docs = sample_document_list
    sorted = sort_documents_by_index(docs, ["one"])
    assert_equal 2, sorted.count
  end

  def test_should_apply_highlighting_markup
    input = "foo HIGHLIGHT_STARTbarHIGHLIGHT_END baz"
    expected = %{foo <strong class="highlight">bar</strong> baz}
    assert_equal expected, h.apply_highlight(input)
  end
end
