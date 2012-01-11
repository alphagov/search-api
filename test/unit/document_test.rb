require "test_helper"
require "document"

class DocumentTest < Test::Unit::TestCase
  def test_should_turn_hash_into_document
    hash = {
      "title" => "TITLE",
      "description" => "DESCRIPTION",
      "format" => "answer",
      "section" => "Life in the UK",
      "link" => "/an-example-answer",
      "indexable_content" => "HERE IS SOME CONTENT",
    }

    document = Document.from_hash(hash)

    assert_equal "TITLE", document.title
    assert_equal "DESCRIPTION", document.description
    assert_equal "answer", document.format
    assert_equal "Life in the UK", document.section
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

  def test_should_expand_additional_links_into_nested_array
    hash = {
      :title => "TITLE",
      :description => "DESCRIPTION",
      :format => "guide",
      :link => "/an-example-guide",
      :indexable_content => "HERE IS SOME CONTENT",
      :additional_links__title => ["LINK TITLE 1", "LINK TITLE 2"],
      :additional_links__link => ["/additional-link-1", "/additional-link-2"]
    }

    document = Document.from_hash(hash)

    assert_equal 2, document.additional_links.length
    assert_equal "LINK TITLE 1", document.additional_links[0].title
    assert_equal "/additional-link-1", document.additional_links[0].link
    assert_equal "LINK TITLE 2", document.additional_links[1].title
    assert_equal "/additional-link-2", document.additional_links[1].link
  end

  def test_should_use_answer_as_presentation_format_for_planner
    hash = {:format => "planner"}

    document = Document.from_hash(hash)
    assert_equal "answer", document.presentation_format
  end

  def test_should_use_answer_as_presentation_format_for_answer
    hash = {:format => "smart_answer"}

    document = Document.from_hash(hash)
    assert_equal "answer", document.presentation_format
  end

  def test_should_use_guide_as_presentation_format_for_guide
    hash = {:format => "guide"}

    document = Document.from_hash(hash)
    assert_equal "guide", document.presentation_format
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

  def test_should_export_additional_links_as_separate_fields
    document = Document.new
    document.additional_links = [
      Link.new.tap{ |l|
        l.title = "LINK TITLE 1"
        l.link  = "/additional-link-1"
      },
      Link.new.tap{ |l|
        l.title = "LINK TITLE 2"
        l.link  = "/additional-link-2"
      },
    ]
    collaborator = mock("DelSolr Document")
    collaborator.expects(:add_field).
      with("additional_links__title", "LINK TITLE 1")
    collaborator.expects(:add_field).
      with("additional_links__link", "/additional-link-1")
    collaborator.expects(:add_field).
      with("additional_links__title", "LINK TITLE 2")
    collaborator.expects(:add_field).
      with("additional_links__link", "/additional-link-2")
    document.solr_export(collaborator)
  end

  def test_should_round_trip_document_from_hash_and_back_into_hash
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
    assert_equal hash, document.to_hash
  end

  def test_should_skip_missing_fields_in_to_hash
    hash = {
      "title" => "TITLE",
      "description" => "DESCRIPTION",
      "format" => "guide",
      "link" => "/an-example-guide",
    }

    document = Document.from_hash(hash)
    assert_equal hash.keys.sort, document.to_hash.keys.sort
  end

  def test_should_use_description_for_highlight_if_no_highlight_is_set
    hash = {
      "description" => "DESCRIPTION",
    }

    document = Document.from_hash(hash)
    assert_equal "DESCRIPTION", document.highlight
  end

  def test_should_prefer_highlight_if_set
    hash = {
      "description" => "DESCRIPTION",
    }

    document = Document.from_hash(hash)
    document.highlight = "HIGHLIGHT"
    assert_equal "HIGHLIGHT", document.highlight
  end
end
