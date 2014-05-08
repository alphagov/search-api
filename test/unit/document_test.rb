require "test_helper"
require "document"

class DocumentTest < MiniTest::Unit::TestCase
  include Fixtures::DefaultMappings

  def setup
    @mappings = default_mappings
  end

  def test_should_turn_hash_into_document
    hash = {
      "title" => "TITLE",
      "description" => "DESCRIPTION",
      "format" => "answer",
      "section" => "Life in the UK",
      "subsection" => 'Queuing',
      "subsubsection" => 'Barging to the front',
      "link" => "/an-example-answer",
      "indexable_content" => "HERE IS SOME CONTENT",
    }

    document = Document.from_hash(hash, @mappings)

    assert_equal "TITLE", document.title
    assert_equal "DESCRIPTION", document.description
    assert_equal "answer", document.format
    assert_equal "Life in the UK", document.section
    assert_equal "Queuing", document.subsection
    assert_equal "Barging to the front", document.subsubsection
    assert_equal "/an-example-answer", document.link
    assert_equal "HERE IS SOME CONTENT", document.indexable_content
  end

  def test_should_turn_hash_with_non_standard_field_into_document
    hash = {
      "title" => "TITLE",
      "description" => "DESCRIPTION",
      "format" => "guide",
      "link" => "/an-example-guide",
      "topics" => [1,2]
    }

    mappings = default_mappings
    mappings['edition']['properties'].merge!({"topics" => { "type" => "string", "index" => "not_analyzed" }})
    document = Document.from_hash(hash, mappings)

    assert_equal [1,2], document.to_hash["topics"]
    assert_equal [1,2], document.topics
    assert_equal [1,2], document.elasticsearch_export["topics"]
  end

  def test_should_permit_nonedition_documents
    hash = {
      "_id" => "jobs_exact",
      "_type" => "best_bet",
      "query" => "jobs"
    }

    mappings = default_mappings.merge(
      "best_bet" => {
        "properties" => {
          "query" => { "type" => "string", "index" => "not_analyzed" }
        }
      }
    )

    document = Document.from_hash(hash, mappings)

    assert_equal "jobs", document.to_hash["query"]
    assert_equal "jobs", document.query
    assert_equal "jobs", document.elasticsearch_export["query"]

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

    document = Document.from_hash(hash, @mappings)

    refute_includes document.to_hash.keys, "some_other_field"
    refute document.respond_to?("some_other_field")
  end

  def test_should_recognise_symbol_keys_in_hash
    hash = {
      :title => "TITLE",
      :description => "DESCRIPTION",
      :format => "guide",
      :link => "/an-example-guide",
      :indexable_content => "HERE IS SOME CONTENT"
    }

    document = Document.from_hash(hash, @mappings)

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

    document = Document.from_hash(hash, @mappings)
    assert_equal hash, document.to_hash
  end

  def test_should_skip_missing_fields_in_to_hash
    hash = {
      "title" => "TITLE",
      "description" => "DESCRIPTION",
      "format" => "guide",
      "link" => "/an-example-guide"
    }

    document = Document.from_hash(hash, @mappings)
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
    document = Document.from_hash(hash, @mappings)

    assert_equal hash.keys.sort, document.elasticsearch_export.keys.sort
  end

  def test_should_include_result_score
    hash = { "link" => "/batman" }
    field_names = ["link"]

    assert_equal 5.2, Document.new(field_names, hash, 5.2).es_score
  end

  def test_includes_elasticsearch_score_in_hash
    hash = { "link" => "/batman" }
    field_names = ["link"]

    assert_equal 5.2, Document.new(field_names, hash, 5.2).to_hash["es_score"]
  end

  def test_leaves_out_blank_score
    hash = { "link" => "/batman" }
    field_names = ["link"]

    refute_includes Document.new(field_names, hash).to_hash, "es_score"
  end

  def test_weighted_score
    document_hash = {"link" => "/batman", "title" => "Batman"}
    doc = Document.new(%w(link title), document_hash, 2.8)

    weighted_doc = doc.weighted(0.5)
    assert_equal "/batman", weighted_doc.link
    assert_equal "Batman", weighted_doc.title
    assert_equal 1.4, weighted_doc.es_score
  end

  def test_weighting_without_score
    document_hash = {"link" => "/batman"}
    doc = Document.new(%w(link), document_hash)

    weighted_doc = doc.weighted(0.5)
    assert_equal "/batman", weighted_doc.link
    assert_nil weighted_doc.es_score
  end
end
