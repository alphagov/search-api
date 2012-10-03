# encoding: utf-8
require "test_helper"

class HelperTest < Test::Unit::TestCase
  def h
    HelperAccessor.new
  end

  def sample_document_list
    doc1 = Document.from_hash({
      "title" => "TITLE",
      "format" => "two",
      "link" => "/two",
    })
    doc2 = Document.from_hash({
      "title" => "TITLE",
      "format" => "one",
      "link" => "/one",
    })
    [doc1, doc2]
  end

  def test_boosting_documents
    boosts = {
      "/one" => "extra extra read all about it",
    }
    boosted_documents = boost_documents(sample_document_list, boosts)
    assert_equal nil, boosted_documents[0].boost_phrases
    assert_equal "extra extra read all about it", boosted_documents[1].boost_phrases
  end

  def test_boosting_documents_with_existing_boost
    documents = [Document.from_hash(
      "title" => "TITLE",
      "format" => "one",
      "link" => "/one",
      "boost_phrases" => "boost this"
    )]
    boosts = {
      "/one" => "extra extra read all about it",
    }
    boosted_documents = boost_documents(documents, boosts)
    assert_equal "boost this extra extra read all about it", boosted_documents[0].boost_phrases
  end

  def test_boosting_documents_without_boost
    boosts = {
    }
    boosted_documents = boost_documents(sample_document_list, boosts)
    assert_equal boosted_documents.count, sample_document_list.count
  end
end
