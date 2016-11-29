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

    document = Document.from_hash(hash, sample_elasticsearch_types)

    assert_equal "TITLE", document.title
    assert_equal "DESCRIPTION", document.description
    assert_equal "answer", document.format
    assert_equal "/an-example-answer", document.link
    assert_equal "HERE IS SOME CONTENT", document.indexable_content
  end

  def test_should_permit_nonedition_documents
    hash = {
      "_id" => "jobs_exact",
      "_type" => "best_bet",
      "stemmed_query" => "jobs"
    }

    document = Document.from_hash(hash, sample_elasticsearch_types)

    assert_equal "jobs", document.to_hash["stemmed_query"]
    assert_equal "jobs", document.stemmed_query
    assert_equal "jobs", document.elasticsearch_export["stemmed_query"]

    refute document.to_hash.has_key?("_type")
    refute document.to_hash.has_key?("_id")
    assert_equal "jobs_exact", document.elasticsearch_export["_id"]
    assert_equal "best_bet", document.elasticsearch_export["_type"]
  end

  def test_should_raise_helpful_error_for_unconfigured_types
    hash = {
      "_id" => "jobs_exact",
      "_type" => "cheese"
    }

    assert_raises RuntimeError do
      Document.from_hash(hash, sample_elasticsearch_types)
    end
  end

  def test_should_ignore_fields_not_in_mappings
    hash = {
      "title" => "TITLE",
      "description" => "DESCRIPTION",
      "format" => "guide",
      "link" => "/an-example-guide",
      "some_other_field" => "test"
    }

    document = Document.from_hash(hash, sample_elasticsearch_types)

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

    document = Document.from_hash(hash, sample_elasticsearch_types)

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

    document = Document.from_hash(hash, sample_elasticsearch_types)
    assert_equal hash, document.to_hash
  end

  def test_should_skip_missing_fields_in_to_hash
    hash = {
      "title" => "TITLE",
      "description" => "DESCRIPTION",
      "format" => "guide",
      "link" => "/an-example-guide"
    }

    document = Document.from_hash(hash, sample_elasticsearch_types)
    assert_equal hash.keys.sort, document.to_hash.keys.sort
  end

  def test_should_skip_missing_fields_in_elasticsearch_export
    hash = {
        "_type" => "edition",
        "title" => "TITLE",
        "description" => "DESCRIPTION",
        "format" => "guide",
        "link" => "/an-example-guide",
    }
    document = Document.from_hash(hash, sample_elasticsearch_types)

    assert_equal hash.keys.sort, document.elasticsearch_export.keys.sort
  end

  def test_should_include_result_score
    hash = { "link" => "/batman" }
    field_names = ["link"]

    assert_equal 5.2, Document.new(sample_field_definitions(field_names), hash, 5.2).es_score
  end

  def test_includes_elasticsearch_score_in_hash
    hash = { "link" => "/batman" }
    field_names = ["link"]

    assert_equal 5.2, Document.new(sample_field_definitions(field_names), hash, 5.2).to_hash["es_score"]
  end

  def test_leaves_out_blank_score
    hash = { "link" => "/batman" }
    field_names = ["link"]

    refute_includes Document.new(sample_field_definitions(field_names), hash).to_hash, "es_score"
  end

  def test_should_handle_opaque_object_fields
    metadata = { "foo" => true, "bar" => 1 }
    document_hash = {
      "metadata" => metadata
    }
    doc = Document.new(sample_field_definitions(%w(metadata)), document_hash)

    assert_equal metadata, doc.metadata
  end
end
