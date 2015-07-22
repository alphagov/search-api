require "test_helper"
require "snippet"

class SnippetTest < MiniTest::Unit::TestCase
  def test_snippet_by_default
    document = { "description" => "Some short description." }

    snippet = Snippet.new(document).text

    assert_equal "Some short description.", snippet
  end

  def test_nil_snippet_is_empty
    document = { "description" => nil }

    snippet = Snippet.new(document).text

    assert_equal "", snippet
  end

  def test_snippet_should_be_truncated
    document = { "description" => "Some looong description." * 20 }

    snippet = Snippet.new(document).text

    assert snippet.size < 215
  end

  def test_organisation_snippet_should_get_prefixed
    document = { "title" => "Ministry of Magic", "format" => "organisation", "organisation_state" => "open", "description" => "A description." }

    snippet = Snippet.new(document).text

    assert_equal "The home of Ministry of Magic on GOV.UK. A description.", snippet
  end

  def test_closed_organisation_snippet_should_not_get_prefixed
    document = { "format" => "organisation", "organisation_state" => "closed", "description" => "A description." }

    snippet = Snippet.new(document).text

    assert_equal "A description.", snippet
  end

  def test_topic_pages_get_a_nice_description_if_they_do_not_have_one
    document = { "format" => "specialist_sector", "title" => "Muggles" }

    snippet = Snippet.new(document).text

    assert_equal "List of information about Muggles.", snippet
  end

  def test_topic_pages_keep_description_if_present
    document = { "format" => "specialist_sector", "description" => "All about Muggles." }

    snippet = Snippet.new(document).text

    assert_equal "All about Muggles.", snippet
  end
end
