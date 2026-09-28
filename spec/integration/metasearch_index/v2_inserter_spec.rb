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
    before do
      post "/v2/metasearch/documents", document.merge("_id" => id).to_json, { "CONTENT_TYPE" => "application/json" }
    end

    it "inserts a new best bet" do
      expect_document_is_in_rummager(document, type: "best_bet", index: SearchConfig.metasearch_index_name, id:)
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq({ result: "Success" }.to_json)
    end

    it "sets endpoint as a prometheus label" do
      expect(last_request.env["govuk.prometheus_labels"][:search_api_endpoint]).to eq("metasearch_documents")
    end
  end

  describe "delete /v2/metasearch/documents/:id" do
    before do
      commit_document(SearchConfig.metasearch_index_name,
                      document,
                      type: "best_bet",
                      id:)
      delete "/v2/metasearch/documents/#{id}"
    end

    it "deletes a best bet" do
      expect_document_missing_in_rummager(id: id, index: SearchConfig.metasearch_index_name)
    end

    it "sets endpoint as a prometheus label" do
      expect(last_request.env["govuk.prometheus_labels"][:search_api_endpoint]).to eq("metasearch_documents")
    end
  end
end
