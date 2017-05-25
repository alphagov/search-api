require "test_helper"
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

    document = Document.new(
      field_definitions: sample_field_definitions,
      type: 'edition',
      source_attributes: hash,
    )

    assert_equal "TITLE", document.title
    assert_equal "DESCRIPTION", document.description
    assert_equal "answer", document.format
    assert_equal "/an-example-answer", document.link
    assert_equal "HERE IS SOME CONTENT", document.indexable_content
  end

  # TODO: what functionality is this testing?
  def test_should_permit_nonedition_documents
    hash = {
      "stemmed_query" => "jobs"
    }

    document = Document.new(
      id: "jobs_exact",
      field_definitions: sample_field_definitions,
      type: 'best_bet',
      source_attributes: hash,
    )

    assert_equal "jobs", document.to_hash["stemmed_query"]
    assert_equal "jobs", document.stemmed_query
    assert_equal "jobs", document.elasticsearch_export["stemmed_query"]

    refute document.to_hash.has_key?("_type")
    refute document.to_hash.has_key?("_id")

    assert_equal "jobs_exact", document.elasticsearch_export["_id"]
    assert_equal "best_bet", document.elasticsearch_export["_type"]
  end

  def test_should_ignore_fields_not_in_mappings
    hash = {
      "title" => "TITLE",
      "description" => "DESCRIPTION",
      "format" => "guide",
      "link" => "/an-example-guide",
      "some_other_field" => "test"
    }

    document = Document.new(
      field_definitions: sample_field_definitions,
      type: 'edition',
      source_attributes: hash,
    )

    refute_includes document.to_hash.keys, "some_other_field"
    refute document.respond_to?("some_other_field")
  end

  def test_should_recognise_symbol_keys_in_hash
    hash = {
      title: "TITLE",
      description: "DESCRIPTION",
      format: "guide",
      link: "/an-example-guide",
      indexable_content: "HERE IS SOME CONTENT"
    }

    document = Document.new(
      field_definitions: sample_field_definitions,
      type: 'edition',
      source_attributes: hash,
    )

    assert_equal "TITLE", document.title
  end

  def test_should_round_trip_document_from_hash_and_back_into_hash
    hash = {
      "title" => "TITLE",
      "description" => "DESCRIPTION",
      "format" => "guide",
      "link" => "/an-example-guide",
      "indexable_content" => "HERE IS SOME CONTENT"
    }

    document = Document.new(
      field_definitions: sample_field_definitions,
      type: 'edition',
      source_attributes: hash,
    )

    assert_equal hash, document.to_hash
  end

  def test_should_skip_missing_fields_in_to_hash
    hash = {
      "title" => "TITLE",
      "description" => "DESCRIPTION",
      "format" => "guide",
      "link" => "/an-example-guide"
    }

    document = Document.new(
      field_definitions: sample_field_definitions,
      type: 'edition',
      source_attributes: hash,
    )

    assert_equal hash.keys.sort, document.to_hash.keys.sort
  end

  # Every document exported from elasticsearch has an ID and Type.
  # These get merged into the export so that we know what type
  # to use when bulk importing them again.
  def test_should_set_meta_fields_in_elasticsearch_export
    hash = {
        "title" => "TITLE",
        "description" => "DESCRIPTION",
        "format" => "guide",
        "link" => "/an-example-guide",
    }

    expected_keys = %w(title description format link _id _type)

    document = Document.new(
      field_definitions: sample_field_definitions,
      type: 'edition',
      source_attributes: hash,
    )

    assert_equal expected_keys.sort, document.elasticsearch_export.keys.sort
  end

  def test_should_include_result_score
    hash = { "link" => "/batman" }
    field_names = ["link"]

    document = Document.new(
      field_definitions: sample_field_definitions,
      type: 'edition',
      source_attributes: hash,
      score: 5.2
    )

    assert_equal 5.2, document.es_score
  end

  def test_includes_elasticsearch_score_in_hash
    hash = { "link" => "/batman" }
    field_names = ["link"]

    document = Document.new(
      field_definitions: sample_field_definitions,
      type: 'edition',
      source_attributes: hash,
      score: 5.2
    )

    assert_equal 5.2, document.to_hash["es_score"]
  end

  def test_leaves_out_blank_score
    hash = { "link" => "/batman" }
    field_names = ["link"]

    document = Document.new(
      field_definitions: sample_field_definitions,
      type: 'edition',
      source_attributes: hash,
    )

    refute_includes document.to_hash, "es_score"
  end

  def test_should_handle_opaque_object_fields
    metadata = { "foo" => true, "bar" => 1 }
    document_hash = {
      "metadata" => metadata
    }

    document = Document.new(
      field_definitions: sample_field_definitions,
      type: 'edition',
      source_attributes: document_hash,
    )

    assert_equal metadata, document.metadata
  end
end
