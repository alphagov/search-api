require "spec_helper"

RSpec.describe "V2MetasearchTest" do
  let(:id) { "ca3916" }
  let(:document) do
    {
      "details" => %({"best_bets":[{"link":"/government/publications/national-insurance-statement-of-national-insurance-contributions-ca3916","position":1}],"worst_bets":[]}),
      "exact_query" => "ca3916",
      "stemmed_query" => nil,
    }
  end
  describe "post /v2/metasearch/documents" do
    it "inserts a new best bet" do
      post "/v2/metasearch/documents", document.merge("_id" => id).to_json, { "CONTENT_TYPE" => "application/json" }
      expect_document_is_in_rummager(document, type: "best_bet", index: SearchConfig.metasearch_index_name, id:)
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq({ result: "Success" }.to_json)
    end
  end

  describe "delete /v2/metasearch/documents/:id" do
    it "deletes a best bet" do
      commit_document(SearchConfig.metasearch_index_name,
                      document,
                      type: "best_bet",
                      id:)
      delete "/v2/metasearch/documents/#{id}"
      expect_document_missing_in_rummager(id: id, index: SearchConfig.metasearch_index_name)
    end
  end
end
