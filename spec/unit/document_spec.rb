require 'spec_helper'

RSpec.describe Document do
  it "should_turn_hash_into_document" do
    hash = {
      "_type" => "edition",
      "title" => "TITLE",
      "description" => "DESCRIPTION",
      "format" => "answer",
      "link" => "/an-example-answer",
      "indexable_content" => "HERE IS SOME CONTENT",
    }

    document = described_class.from_hash(hash, sample_elasticsearch_types)

    expect(document.title).to eq("TITLE")
    expect(document.description).to eq("DESCRIPTION")
    expect(document.format).to eq("answer")
    expect(document.link).to eq("/an-example-answer")
    expect(document.indexable_content).to eq("HERE IS SOME CONTENT")
  end

  it "should_permit_nonedition_documents" do
    hash = {
      "_id" => "jobs_exact",
      "_type" => "best_bet",
      "stemmed_query" => "jobs"
    }

    document = described_class.from_hash(hash, sample_elasticsearch_types)

    expect(document.to_hash["stemmed_query"]).to eq("jobs")
    expect(document.stemmed_query).to eq("jobs")
    expect(document.elasticsearch_export["stemmed_query"]).to eq("jobs")

    expect(document.to_hash.has_key?("_type")).to be_falsey
    expect(document.to_hash.has_key?("_id")).to be_falsey
    expect(document.elasticsearch_export["_id"]).to eq("jobs_exact")
    expect(document.elasticsearch_export["_type"]).to eq("best_bet")
  end

  it "should_reject_document_with_no_type" do
    hash = {
      "_id" => "some_id",
    }

    expect {
      described_class.from_hash(hash, sample_elasticsearch_types)
    }.to raise_error(/missing/i)
  end

  it "should_raise_helpful_error_for_unconfigured_types" do
    hash = {
      "_id" => "jobs_exact",
      "_type" => "cheese"
    }

    expect {
      described_class.from_hash(hash, sample_elasticsearch_types)
    }.to raise_error(RuntimeError)
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

    document = described_class.from_hash(hash, sample_elasticsearch_types)

    expect(document.to_hash.keys).not_to include("some_other_field")
    expect(document.respond_to?("some_other_field")).to be_falsey
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

    document = described_class.from_hash(hash, sample_elasticsearch_types)

    expect(document.title).to eq("TITLE")
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

    document = described_class.from_hash(input_hash, sample_elasticsearch_types)
    expect(expected_hash).to eq(document.to_hash)
  end

  it "should_skip_missing_fields_in_to_hash" do
    document = described_class.from_hash({ "_type" => "edition" }, sample_elasticsearch_types)
    expect(document.to_hash.keys).to eq([])
  end

  it "should_skip_missing_fields_in_elasticsearch_export" do
    hash = {
        "_type" => "edition",
        "title" => "TITLE",
        "description" => "DESCRIPTION",
        "format" => "guide",
        "link" => "/an-example-guide",
    }
    document = described_class.from_hash(hash, sample_elasticsearch_types)

    expect(hash.keys.sort).to eq(document.elasticsearch_export.keys.sort)
  end

  it "should_include_result_score" do
    hash = { "link" => "/batman" }
    field_names = ["link"]

    expect(5.2).to eq(described_class.new(sample_field_definitions(field_names), hash, 5.2).es_score)
  end

  it "includes_elasticsearch_score_in_hash" do
    hash = { "link" => "/batman" }
    field_names = ["link"]

    expect(5.2).to eq(described_class.new(sample_field_definitions(field_names), hash, 5.2).to_hash["es_score"])
  end

  it "leaves_out_blank_score" do
    hash = { "link" => "/batman" }
    field_names = ["link"]

    expect(described_class.new(sample_field_definitions(field_names), hash).to_hash).not_to include("es_score")
  end

  it "should_handle_opaque_object_fields" do
    metadata = { "foo" => true, "bar" => 1 }
    document_hash = {
      "metadata" => metadata
    }
    doc = described_class.new(sample_field_definitions(%w(metadata)), document_hash)

    expect(metadata).to eq(doc.metadata)
  end
end
