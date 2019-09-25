require "spec_helper"

RSpec.describe MetasearchIndex::Deleter::V2 do
  context "instantiation" do
    it "raises an error when a blank id is passed in" do
      expect do
        described_class.new(id: nil)
      end.to raise_error(ArgumentError)

      expect do
        described_class.new(id: "")
      end.to raise_error(ArgumentError)
    end

    it "does not raise an error when all fields are present" do
      expect do
        described_class.new(id: "id")
      end.not_to raise_error
    end
  end

  it "can delete an existing document" do
    document = {
      "details" => %[{"best_bets":[{"link":"/government/publications/national-insurance-statement-of-national-insurance-contributions-ca3916","position":1}],"worst_bets":[]}],
      "exact_query" => "ca3916",
      "stemmed_query" => nil,
      "stemmed_query_as_term" => nil,
    }
    commit_document("metasearch_test", document, type: "best_bet", id: "ca3916-exact")
    described_class.new(id: "ca3916-exact").delete

    expect do
      fetch_document_from_rummager(type: "best_bet", index: "metasearch_test", id: "ca3916-exact")
    end.to raise_error(Elasticsearch::Transport::Transport::Errors::NotFound)
  end

  it "will raise an error when trying to delete a non-existant document" do
    expect do
      described_class.new(id: "ca3916-exact").delete
    end.to raise_error(Index::ResponseValidator::NotFound)
  end

  it "raises an error if the process fails to delete in elasticsearch" do
    failure_reponse = [{
      "items" => [{ "insert" => { "status" => 500 } }],
    }]
    expect_any_instance_of(Index::ElasticsearchProcessor).to receive(:commit).and_return(failure_reponse)
    expect do
      described_class.new(id: "ca3916-exact").delete
    end.to raise_error(Index::ResponseValidator::ElasticsearchError)
  end
end
