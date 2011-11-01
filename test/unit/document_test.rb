require "document"

class DocumentTest < MiniTest::Unit::TestCase
  def test_should_turn_hash_into_document
    hash = {
      "title" => "TITLE",
      "description" => "DESCRIPTION",
      "format" => "answer",
      "link" => "/an-example-answer",
      "indexable_content" => "HERE IS SOME CONTENT",
    }

    document = Document.from_hash(hash)

    assert_equal "TITLE", document.title
    assert_equal "DESCRIPTION", document.description
    assert_equal "answer", document.format
    assert_equal "/an-example-answer", document.link
    assert_equal "HERE IS SOME CONTENT", document.indexable_content
  end

  def test_should_turn_hash_with_additional_links_into_document
    hash = {
      "title" => "TITLE",
      "description" => "DESCRIPTION",
      "format" => "guide",
      "link" => "/an-example-guide",
      "indexable_content" => "HERE IS SOME CONTENT",
      "additional_links" => [
        {"title" => "LINK TITLE 1", "link" => "/additional-link-1"},
        {"title" => "LINK TITLE 2", "link" => "/additional-link-2"},
      ]
    }

    document = Document.from_hash(hash)

    assert_equal "LINK TITLE 1", document.additional_links.first.title
    assert_equal "/additional-link-1", document.additional_links.first.link
  end

  def test_should_have_no_additional_links_if_none_in_hash
    hash = {
      "title" => "TITLE",
      "description" => "DESCRIPTION",
      "format" => "answer",
      "link" => "/an-example-answer",
      "indexable_content" => "HERE IS SOME CONTENT",
    }

    document = Document.from_hash(hash)

    assert_equal [], document.additional_links
  end
end
