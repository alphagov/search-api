require "spec_helper"

RSpec.describe MetasearchIndex::Inserter::V2 do
  context "instantiation" do
    it "raises an error when a blank id is passed in" do
      expect {
        described_class.new(id: nil, document: { a: "doc" })
      }.to raise_error(ArgumentError)

      expect {
        described_class.new(id: "", document: { a: "doc" })
      }.to raise_error(ArgumentError)
    end

    it "raises an error when a blank document is passed in" do
      expect {
        described_class.new(id: "id", document: nil)
      }.to raise_error(ArgumentError)

      expect {
        described_class.new(id: "id", document: {})
      }.to raise_error(ArgumentError)
    end

    it "does not raise an error when all fields are present" do
      expect {
        described_class.new(id: "id", document: { a: "doc" })
      }.not_to raise_error
    end
  end

  it "can insert a new document" do
    document = {
      "details" => %({"best_bets":[{"link":"/government/publications/national-insurance-statement-of-national-insurance-contributions-ca3916","position":1}],"worst_bets":[]}),
      "exact_query" => "ca3916",
      "stemmed_query" => nil,
    }
    described_class.new(id: "ca3916-exact", document:).insert
    commit_index("metasearch_test")

    expect_document_is_in_rummager(document, type: "best_bet", index: "metasearch_test", id: "ca3916-exact")
  end

  it "can insert a new stemmed document" do
    document = {
      "details" => %({"best_bets":[{"link":"/government/publications/national-insurance-statement-of-national-insurance-contributions-ca3916","position":1}],"worst_bets":[]}),
      "exact_query" => nil,
      "stemmed_query" => "car taxes",
    }
    described_class.new(id: "car tax-stemmed", document:).insert
    commit_index("metasearch_test")

    expect_document_is_in_rummager(
      document.merge("stemmed_query_as_term" => " car tax "),
      type: "best_bet",
      index: "metasearch_test",
      id: "car tax-stemmed",
    )
  end

  it "can overwrite an existing document" do
    old_document = {
      "details" => %({"best_bets":[],"worst_bets":[]}),
      "exact_query" => "ca3916-none",
    }
    commit_document("metasearch_test", old_document, type: "best_bet", id: "ca3916-exact")

    document = {
      "details" => %({"best_bets":[{"link":"/government/publications/national-insurance-statement-of-national-insurance-contributions-ca3916","position":1}],"worst_bets":[]}),
      "exact_query" => "ca3916",
      "stemmed_query" => nil,
    }
    described_class.new(id: "ca3916-exact", document:).insert
    commit_index("metasearch_test")

    expect_document_is_in_rummager(document, type: "best_bet", index: "metasearch_test", id: "ca3916-exact")
  end

  it "raises an error if the process fails to write to elasticsearch" do
    failure_reponses = [{
      "items" => [{ "insert" => { "status" => 500 } }],
    }]
    expect_any_instance_of(Index::ElasticsearchProcessor).to receive(:commit).and_return(failure_reponses)

    document = {
      "details" => %({"best_bets":[{"link":"/government/publications/national-insurance-statement-of-national-insurance-contributions-ca3916","position":1}],"worst_bets":[]}),
      "exact_query" => "ca3916",
      "stemmed_query" => nil,
    }
    expect {
      described_class.new(id: "ca3916-exact", document:).insert
    }.to raise_error(Index::ResponseValidator::ElasticsearchError)
  end
end
