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
      "link" => "/two",
    })
    doc2 = Document.from_hash({
      "title" => "TITLE",
      "format" => "one",
      "link" => "/one",
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
    assert_match expected, h.apply_highlight(input)
  end

  def test_should_prepend_ellipsis_if_phrase_starts_with_lower_case
    assert_match /\A… foo/, h.apply_highlight("foo")
  end

  def test_should_not_prepend_ellipsis_if_phrase_starts_with_upper_case
    assert_no_match /\A…/, h.apply_highlight("Foo")
  end

  def test_should_prepend_ellipsis_if_phrase_starts_with_highlighted_lower_case
    assert_match /\A…/, h.apply_highlight("HIGHLIGHT_STARTfooHIGHLIGHT_END")
  end

  def test_should_not_prepend_ellipsis_if_phrase_starts_with_highlighted_upper_case
    assert_no_match /\A…/, h.apply_highlight("HIGHLIGHT_STARTFooHIGHLIGHT_END")
  end

  def test_should_append_ellipsis_if_phrase_ends_with_non_punctuation
    assert_match /foo …\z/, h.apply_highlight("foo")
  end

  def test_should_not_append_ellipsis_if_phrase_ends_with_punctuation
    assert_no_match /…\z/, h.apply_highlight("foo.")
    assert_no_match /…\z/, h.apply_highlight("foo!")
    assert_no_match /…\z/, h.apply_highlight("foo?")
  end

  def test_should_append_ellipsis_if_phrase_ends_with_highlighted_non_punctuation
    assert_match /…\z/, h.apply_highlight("HIGHLIGHT_STARTfooHIGHLIGHT_END")
  end

  def test_should_not_append_ellipsis_if_phrase_ends_with_highlighted_punctuation
    assert_no_match /…\z/, h.apply_highlight("HIGHLIGHT_STARTfoo.HIGHLIGHT_END")
  end

  def test_should_ignore_space_when_adding_ellipses
    assert_equal "… foo …", h.apply_highlight(" foo ")
  end

  def test_should_return_blank_when_highlighting_an_empty_string
    assert_equal "", h.apply_highlight(" ")
  end

  def test_should_not_start_with_ellipsis_if_grammar_mark_found
    input = " - find you emergency accommodation - look at other options including living with a"
    expected = "… find you emergency accommodation - look at other options including living with a …"
    assert_equal expected, h.apply_highlight(input)
  end

  def test_should_not_start_with_a_punctuation_mark
    assert_equal "- read the …", h.apply_highlight(") - read the ")
  end

  def test_should_remove_single_character_and_space_unless_allowed
    assert_equal "… welcome …", h.apply_highlight("'t welcome")
    assert_equal "… welcome …", h.apply_highlight(".;'t welcome")
    assert_equal "… a box …", h.apply_highlight("a box")
  end
end
