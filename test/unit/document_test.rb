require "test_helper"
require "document"

class DocumentTest < Test::Unit::TestCase
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

  def test_should_recognise_symbol_keys_in_hash
    hash = {
      :title => "TITLE",
      :description => "DESCRIPTION",
      :format => "guide",
      :link => "/an-example-guide",
      :indexable_content => "HERE IS SOME CONTENT",
      :additional_links => [
        {:title => "LINK TITLE 1", :link => "/additional-link-1"},
      ]
    }

    document = Document.from_hash(hash)

    assert_equal "TITLE", document.title
    assert_equal "LINK TITLE 1", document.additional_links.first.title
  end

  def test_should_export_title_to_delsolr_collaborator
    document = Document.new
    document.title = "TITLE"
    collaborator = mock("DelSolr Document")
    collaborator.expects(:add_field).with("title", "TITLE")
    document.solr_export(collaborator)
  end

  def test_should_export_description_to_delsolr_collaborator
    document = Document.new
    document.description = "DESCRIPTION"
    collaborator = mock("DelSolr Document")
    collaborator.expects(:add_field).with("description", "DESCRIPTION")
    document.solr_export(collaborator)
  end

  def test_should_export_format_to_delsolr_collaborator
    document = Document.new
    document.format = "answer"
    collaborator = mock("DelSolr Document")
    collaborator.expects(:add_field).with("format", "answer")
    document.solr_export(collaborator)
  end

  def test_should_export_link_to_delsolr_collaborator
    document = Document.new
    document.link = "/an-example-answer"
    collaborator = mock("DelSolr Document")
    collaborator.expects(:add_field).with("link", "/an-example-answer")
    document.solr_export(collaborator)
  end

  def test_should_export_indexable_content_to_delsolr_collaborator
    document = Document.new
    document.indexable_content = "HERE IS SOME CONTENT"
    collaborator = mock("DelSolr Document")
    collaborator.expects(:add_field).
      with("indexable_content", "HERE IS SOME CONTENT")
    document.solr_export(collaborator)
  end
end
