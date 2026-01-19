require "spec_helper"

RSpec.describe "ElasticsearchDeletionTest" do
  describe "delete /:index/documents/*" do
    it_behaves_like "govuk and detailed index protection", "/:index/documents/%2Fan-example-page", method: :delete
    it_behaves_like "rejects unknown index", "/unknown/documents/%2Fan-example-page", method: :delete

    it "removes a document from the index" do
      commit_document(
        "government_test",
        {
          "link" => "/an-example-page",
        },
      )

      delete "/government_test/documents/%2Fan-example-page"

      expect_document_missing_in_rummager(id: "/an-example-page", index: "government_test")
    end

    it "removes a document from the index, explicitly giving the type" do
      commit_document(
        "government_test",
        { "link" => "/an-example-page" },
        type: "generic-document",
      )

      delete "/government_test/documents/%2Fan-example-page",
             { document_type: "generic-document" }.to_json,
             { "CONTENT_TYPE" => "application/json" }

      expect_document_missing_in_rummager(id: "/an-example-page", index: "government_test", type: "generic-document")
    end

    it "removes a document from the index queued" do
      commit_document(
        "government_test",
        {
          "link" => "/an-example-page",
        },
      )

      delete "/government_test/documents/%2Fan-example-page"

      expect(last_response.status).to eq(202)
    end

    it "removes document with url" do
      commit_document(
        "government_test",
        {
          "link" => "http://example.com/",
        },
      )

      delete "/government_test/documents/edition/http:%2F%2Fexample.com%2F"

      expect_document_missing_in_rummager(id: "http://example.com/", index: "government_test")
    end

    it "deletes a best bet by type and id" do
      post "/metasearch_test/documents",
           {
             "_id" => "jobs_exact",
             "_type" => "best_bet",
             "link" => "/something",
           }.to_json

      commit_index("metasearch_test")

      delete "/metasearch_test/documents/best_bet/jobs_exact"

      expect {
        client.get(
          index: "metasearch_test",
          type: "best_bet",
          id: "jobs_exact",
        )
      }.to raise_error(Elasticsearch::Transport::Transport::Errors::NotFound)
    end
  end
  describe "delete /:index/documents" do
    it "no longer supports the 'delete_all' option" do
      delete "/government_test/documents", delete_all: true
      expect(last_response.status).to eq(400)
    end
    it "removes a document from the index" do
      commit_document("government_test", { "link" => "/an-example-page" })

      delete "/government_test/documents", link: "/an-example-page"

      expect_document_missing_in_rummager(id: "/an-example-page", index: "government_test")
      expect(last_response.status).to eq(200)
    end

    it_behaves_like "govuk and detailed index protection", "/:index/documents", method: :delete
    it_behaves_like "rejects unknown index", "/unknown_index/documents", method: :delete
  end
end
