require 'spec_helper'

RSpec.describe 'DocumentTest' do
  it "should_turn_hash_into_document" do
    hash = {
      "_type" => "edition",
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

  it "should_permit_nonedition_documents" do
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

  it "should_reject_document_with_no_type" do
    hash = {
      "_id" => "some_id",
    }

    error = assert_raises RuntimeError do
      Document.from_hash(hash, sample_elasticsearch_types)
    end
    assert_match(/missing/i, error.message)
  end

  it "should_raise_helpful_error_for_unconfigured_types" do
    hash = {
      "_id" => "jobs_exact",
      "_type" => "cheese"
    }

    assert_raises RuntimeError do
      Document.from_hash(hash, sample_elasticsearch_types)
    end
  end

  it "should_ignore_fields_not_in_mappings" do
    hash = {
      "_type" => "edition",
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

  it "should_recognise_symbol_keys_in_hash" do
    hash = {
      "_type" => "edition",
      title: "TITLE",
      description: "DESCRIPTION",
      format: "guide",
      link: "/an-example-guide",
      indexable_content: "HERE IS SOME CONTENT"
    }

    document = Document.from_hash(hash, sample_elasticsearch_types)

    assert_equal "TITLE", document.title
  end

  it "should_skip_metadata_fields_in_to_hash" do
    expected_hash = {
      "title" => "TITLE",
      "description" => "DESCRIPTION",
      "format" => "guide",
      "link" => "/an-example-guide",
      "indexable_content" => "HERE IS SOME CONTENT",
    }
    input_hash = expected_hash.merge("_type" => "edition")

    document = Document.from_hash(input_hash, sample_elasticsearch_types)
    assert_equal expected_hash, document.to_hash
  end

  it "should_skip_missing_fields_in_to_hash" do
    document = Document.from_hash({ "_type" => "edition" }, sample_elasticsearch_types)
    assert_equal [], document.to_hash.keys
  end

  it "should_skip_missing_fields_in_elasticsearch_export" do
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

  it "should_include_result_score" do
    hash = { "link" => "/batman" }
    field_names = ["link"]

    assert_equal 5.2, Document.new(sample_field_definitions(field_names), hash, 5.2).es_score
  end

  it "includes_elasticsearch_score_in_hash" do
    hash = { "link" => "/batman" }
    field_names = ["link"]

    assert_equal 5.2, Document.new(sample_field_definitions(field_names), hash, 5.2).to_hash["es_score"]
  end

  it "leaves_out_blank_score" do
    hash = { "link" => "/batman" }
    field_names = ["link"]

    refute_includes Document.new(sample_field_definitions(field_names), hash).to_hash, "es_score"
  end

  it "should_handle_opaque_object_fields" do
    metadata = { "foo" => true, "bar" => 1 }
    document_hash = {
      "metadata" => metadata
    }
    doc = Document.new(sample_field_definitions(%w(metadata)), document_hash)

    assert_equal metadata, doc.metadata
  end
end
