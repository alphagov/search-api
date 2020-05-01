require "spec_helper"

RSpec.describe Document do
  it "turns hash into document" do
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

  it "permits nonedition documents" do
    hash = {
      "_id" => "jobs_exact",
      "_type" => "best_bet",
      "stemmed_query" => "jobs",
    }

    document = described_class.from_hash(hash, sample_elasticsearch_types)

    expect(document.to_hash["stemmed_query"]).to eq("jobs")
    expect(document.stemmed_query).to eq("jobs")
    expect(document.elasticsearch_export["stemmed_query"]).to eq("jobs")

    expect(document.to_hash).not_to have_key("_type")
    expect(document.to_hash).not_to have_key("_id")
    expect(document.elasticsearch_export["_id"]).to eq("jobs_exact")
    expect(document.elasticsearch_export["document_type"]).to eq("best_bet")
  end

  it "rejects document with no type" do
    hash = {
      "_id" => "some_id",
    }

    expect {
      described_class.from_hash(hash, sample_elasticsearch_types)
    }.to raise_error(/missing/i)
  end

  it "raises helpful error for unconfigured types" do
    hash = {
      "_id" => "jobs_exact",
      "_type" => "cheese",
    }

    expect {
      described_class.from_hash(hash, sample_elasticsearch_types)
    }.to raise_error(RuntimeError)
  end

  it "ignores fields not in mappings" do
    hash = {
      "_type" => "edition",
      "title" => "TITLE",
      "description" => "DESCRIPTION",
      "format" => "guide",
      "link" => "/an-example-guide",
      "some_other_field" => "test",
    }

    document = described_class.from_hash(hash, sample_elasticsearch_types)

    expect(document.to_hash.keys).not_to include("some_other_field")
    expect(document).not_to respond_to("some_other_field")
  end

  it "recognises symbol keys in hash" do
    hash = {
      "_type" => "edition",
      title: "TITLE",
      description: "DESCRIPTION",
      format: "guide",
      link: "/an-example-guide",
      indexable_content: "HERE IS SOME CONTENT",
    }

    document = described_class.from_hash(hash, sample_elasticsearch_types)

    expect(document.title).to eq("TITLE")
  end

  it "skips metadata fields in to hash" do
    expected_hash = {
      "title" => "TITLE",
      "description" => "DESCRIPTION",
      "format" => "guide",
      "link" => "/an-example-guide",
      "indexable_content" => "HERE IS SOME CONTENT",
    }
    input_hash = expected_hash.merge("document_type" => "edition")

    document = described_class.from_hash(input_hash, sample_elasticsearch_types)
    expect(expected_hash).to eq(document.to_hash)
  end

  it "skips missing fields in to hash" do
    document = described_class.from_hash({ "document_type" => "edition" }, sample_elasticsearch_types)
    expect(document.to_hash.keys).to eq([])
  end

  it "skips missing fields in elasticsearch export" do
    hash = {
        "_type" => "generic-document",
        "document_type" => "edition",
        "title" => "TITLE",
        "description" => "DESCRIPTION",
        "format" => "guide",
        "link" => "/an-example-guide",
    }
    document = described_class.from_hash(hash, sample_elasticsearch_types)

    expect(hash.keys.sort).to eq(document.elasticsearch_export.keys.sort)
  end

  it "includes result score" do
    hash = { "link" => "/batman" }
    field_names = %w[link]

    expect(5.2).to eq(described_class.new(sample_field_definitions(field_names), hash, 5.2).es_score)
  end

  it "includes elasticsearch score in hash" do
    hash = { "link" => "/batman" }
    field_names = %w[link]

    expect(5.2).to eq(described_class.new(sample_field_definitions(field_names), hash, 5.2).to_hash["es_score"])
  end

  it "leaves out blank score" do
    hash = { "link" => "/batman" }
    field_names = %w[link]

    expect(described_class.new(sample_field_definitions(field_names), hash).to_hash).not_to include("es_score")
  end

  it "handles opaque object fields" do
    metadata = { "foo" => true, "bar" => 1 }
    document_hash = {
      "metadata" => metadata,
    }
    doc = described_class.new(sample_field_definitions(%w[metadata]), document_hash)

    expect(metadata).to eq(doc.metadata)
  end
end
