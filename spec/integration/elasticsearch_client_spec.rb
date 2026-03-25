require "spec_helper"

RSpec.describe ElasticsearchClient do
  before do
    stub_const("Hits", EsExtract::Hits)
    stub_const("TopHits", EsExtract::TopHits)
    stub_const("Buckets", EsExtract::Buckets)
    stub_const("Response", EsExtract::Response)
    stub_const("Bulk", EsExtract::Bulk)
    stub_const("BulkItem", EsExtract::BulkItem)
    stub_const("BulkError", EsExtract::BulkError)
  end

  let(:index_name) { "govuk_test" }
  # returns: {"tokens" =>
  #   [{"token" => "what", "start_offset" => 0, "end_offset" => 4, "type" => "<ALPHANUM>", "position" => 0},
  # ...]}
  it "returns token data" do
    result = ElasticsearchClient.analyze(query: "how much is my tax bill going to be next year?",
                                         index_name:,
                                         analyzer: "english")
    expect(result["tokens"]).to be_a(Array)
    expect(result["tokens"].first.keys).to match_array(["token", "start_offset", "end_offset", "type", "position"])
    expect(result["tokens"].first.values).to all(be_a(String).or(be_a(Integer)))
  end

  # returns:
  #{ "took" => 39,
  #  "errors" => false,
  #  "items" => [{"index" => { "_index" => "govuk_test-2026-03-26t14-25-41z-7979adac-3e7a-4a30-bbfb-abe53b741a2b",
  #                             "_type" => "generic-document",
  #                             "_id" => "1",
  #                             "_version" => 1,
  #                             "result" => "created",
  #                             "_shards" => { "total" => 3, "successful" => 1, "failed" => 0 },
  #                             "_seq_no" => 0,
  #                             "_primary_term" => 1,
  #                             "status" => 201 } },
  #                {"create" => ...}
  #                {"update" => ...}
  #                {"delete" => ...}]
  # }
  it "returns bulk data without errors" do
    body = [
        # INDEX (create or overwrite)
        { index: { _index: index_name, _id: 1 } },
        { name: 'Alice', age: 30 },

        # CREATE (fail if exists)
        { create: { _index: index_name, _id: 2 } },
        { name: 'Bob', age: 25 },

        # UPDATE (partial update)
        { update: { _index: index_name, _id: 1 } },
        { doc: { age: 31 } },

        # DELETE
        { delete: { _index: index_name, _id: 2 } },
      ]

    response = ElasticsearchClient.bulk(body:, index_name:)

    expect(Bulk.took(response)).to be_a(Integer)
    expect(Bulk.errors?(response)).to be(false)
    expect(Bulk.actions(response)).to match_array(%w[index create update delete])
  end

  # returns:
  #{"took" => 4,
  # "errors" => true,
  # "items" => [{"index" =>
  #                {"_index" => "govuk_test-2026-03-26t14-32-00z-c2c7b1b0-7380-42f1-b207-23e9b955f34a",
  #                 "_type" => "generic-document",
  #                 "_id" => "1",
  #                 "status" => 400,
  #                 "error" => {"type" => "mapper_parsing_exception",
  #                             "reason" => "failed to parse field [updated_at] of type [date] in document with id '1'",
  #                             "caused_by" => {"type" => "illegal_argument_exception", "reason" => "Invalid format: \"I am not a date\""}}}}]}          ]
  it "returns bulk data with errors" do
    body = [
      { index: { _index: index_name, _id: 1 } },
      { updated_at: "I am not a date" },
    ]

    response = ElasticsearchClient.bulk(body:, index_name:)

    expect(Bulk.errors?(response)).to be(true)
    failure = Bulk.failures(response).first
    expect(BulkError.type(failure)).to eq("mapper_parsing_exception")
    expect(BulkError.reason(failure)).to include("failed to parse")
    expect(BulkError.caused_by_reason(failure)).to eq("Invalid format: \"I am not a date\"")
  end

  it "refreshes the index" do
    result = ElasticsearchClient.refresh_index(index_name:)
    expect(result.dig("_shards", "failed")).to eq(0)
    expect(result.dig("_shards", "successful")).to be > 0
  end

  describe "#delete" do
    it "returns true if the item does not exist" do
      result = ElasticsearchClient.delete(index_name:, id: 1)
      expect(result).to be true
    end
    it "deletes the item if it exists exist" do
      id = commit_document(index_name, { name: "test" })
      result = ElasticsearchClient.delete(index_name:, id:)
      expect(result["result"]).to eq("deleted")
    end
    it "raises an error if the index is locked" do
      id = commit_document(index_name, { name: "test" },)

      ElasticsearchClient.lock_index(index_name:)
      expect { ElasticsearchClient.delete(index_name:, id:) }.to raise_error(ElasticsearchClient::IndexLocked)
    ensure
      ElasticsearchClient.unlock_index(index_name:)
    end
  end

  describe "#get_by_id" do
    #returns:
    # {
    #   "_index": "govuk_test-2026-03-27t10-12-04z-1d3c1f6a-00e4-457d-978e-040abcd8a202",
    #   "_type": "generic-document",
    #   "_id": "/test/90a08e35-7cb2-4baf-bc33-93574382aa0b",
    #   "_version": 1,
    #   "_seq_no": 0,
    #   "_primary_term": 1,
    #   "found": true,
    #   "_source": {
    #     "name": "test",
    #     "document_type": "edition",
    #     "link": "/test/90a08e35-7cb2-4baf-bc33-93574382aa0b"
    #   }
    # }
    it "finds a document by id and returns it" do
      id = commit_document(index_name, { name: "test" })
      result = ElasticsearchClient.get_by_id(index_name:, id:)
      expect(result["_index"]).to start_with(index_name)
      expect(result["_id"]).to eq(id)
      expect(result["found"]).to be true
      expect(result["_source"]["name"]).to eq("test")
    end
    it "raises ElasticsearchClient::Error if the document does not exist" do
      expect { ElasticsearchClient.get_by_id(index_name:, id: 1) }.to raise_error(ElasticsearchClient::Error)
    end
  end

  # returns:
  # {
  #   "page-traffic_test-2026-03-27t15-50-08z-b8c672d1-2f5f-4854-906e-1846a8b59a68": {
  #     "aliases": {
  #       "page-traffic_test": {}
  #     }
  #   },
  #   "government_test-2026-03-27t15-50-07z-d2c1e1ea-93aa-4538-b729-6b6e104f5bcd": {
  #     "aliases": {
  #       "government_test": {}
  #     }
  #   },
  #   "govuk_test-2026-03-27t15-50-08z-c30074f3-4b57-4b35-88f3-b87ed8cc0db7": {
  #     "aliases": {
  #       "govuk_test": {}
  #     }
  #   },
  #   "metasearch_test-2026-03-27t15-50-08z-e4bbbecc-3e47-477c-9ffe-3995bd2e515a": {
  #     "aliases": {
  #       "metasearch_test": {}
  #     }
  #   }
  # }
  describe "#get_alias" do
    it "gets all aliases" do
      result = ElasticsearchClient.get_alias(index_name: "*_test*")
      expect(result.keys).to all(match(/\A[a-z_-]+[_-]test.*/))
      expect(result.values.map(&:keys)).to all(eq(%w[aliases]))
      expect(result.values.flat_map(&:values).flat_map(&:keys)).to all(match(/\A[a-z_-]+[_-]test/))
    end
    it "raises an error if the index cannot be found" do
      expect { ElasticsearchClient.get_alias(index_name: "something_test_I-do-not-exist") }.to raise_error(ElasticsearchClient::Error)
    end
  end

  describe "#set_alias" do
    it "sets and removes an alias" do
      index_name = ElasticsearchClient.get_alias(index_name: "*_test*").keys.first
      result = ElasticsearchClient.set_alias(actions: { "add" => { "index" => index_name, "alias" => "alias_test" }})
      expect(result["acknowledged"]).to be true
      expect { ElasticsearchClient.get_alias(index_name: "alias_test") }.to_not raise_error
    ensure
      ElasticsearchClient.set_alias(actions: { "remove" => { "index" => index_name, "alias" => "alias_test" } })
    end
  end

  describe "#index_recovery" do
    #returns
    # {govuk-2026-03-25t13-15-50z-78fba4a2-540a-4d0b-ae7d-55429bb39b79" =>
    #   {"shards" =>
    #     [{...
    #       "stage" => "DONE",}
    it "returns recovery information for an index" do
      result = ElasticsearchClient.index_recovery(index_name:)
      expect(result.keys).to all(include(index_name))
      expect(result.values.flat_map{_1["shards"]}.map{_1["stage"]}).to all(eq("DONE"))
    end
  end

  describe "#lock_index" do
    it "locks an index and acknowledges the result" do
      result = ElasticsearchClient.lock_index(index_name:)
      expect(result).to eq("acknowledged" => true)
    ensure
      ElasticsearchClient.unlock_index(index_name:)
    end
  end

  describe "#unlock_index" do
    it "unlocks an index and acknowledges the result" do
      result = ElasticsearchClient.unlock_index(index_name:)
      expect(result).to eq("acknowledged" => true)
    end
  end

  describe "#search" do
    before do
      commit_document(index_name, { title: "test", content_id: "123" })
      commit_document(index_name, { title: "test2", content_id: "123" })
    end
    it "returns a result" do
      response = ElasticsearchClient.search(index_name:, body: { query: { match_all: {} } })
      expect(Hits.array(response).map{ Hits.source(_1, "title") }).to match_array(%w[test test2])
    end
    it "counts the number of documents" do
      response = ElasticsearchClient.search(index_name:, body: { query: { match_all: {} } })
      expect(Hits.total(response)).to eq(2)
    end
    it "returns aggregations" do
      body = {
        aggs: {
          dupes: {
            terms: {
              field: "content_id",
              size: 100_000,
              min_doc_count: 2,
            },
            aggs: {
              docs: {
                top_hits: {
                  _source: %w[content_id title],
                  size: 100,
                },
              },
            },
          },
        },
      }
      response = ElasticsearchClient.search(index_name:, body:)
      buckets = Response.buckets(response, "dupes")

      expect(buckets.count).to eq(1)
      bucket = buckets.first

      expect(Buckets.key(bucket)).to eq("123")
      expect(Buckets.doc_count(bucket)).to eq(2)
      expect(TopHits.total(bucket, "docs")).to eq(2)
      expect(
        TopHits.hits(bucket, "docs").map { |hit| Hits.source(hit, "title") }
      ).to match_array(["test", "test2"])
    end
    it "can return a scrolling response" do
      body = { query: { match_all: {} } }
      response = ElasticsearchClient.search(index_name:, body:, scroll: "1m", size: 100, search_type: "query_then_fetch", version: true)
      expect(Hits.total(response)).to eq(2)
      expect(Hits.array(response).map { Hits.source(_1, "title") }).to match_array(%w[test test2])
      expect(Response.scroll_id(response)).to be_a(String)
      expect(Response.scroll_id(response).length).to be > 10
    end
  end

  describe "scroll" do
    it "can scroll documents" do
      body = { query: { match_all: {} } }

      8.times { commit_document(index_name, { title: "test", content_id: "123" }) }
      search_response = ElasticsearchClient.search(index_name:, body:, scroll: "1m", size: 5, search_type: "query_then_fetch", version: true)
      scroll_id = Response.scroll_id(search_response)
      response = ElasticsearchClient.scroll(scroll_id:, scroll: "1m")
      expect(Hits.total(response)).to eq(8)
      expect(Hits.array(response).map{ Hits.source(_1, "title") }).to all(eq("test"))
      expect(Hits.array(response).count).to eq(3)
    end
  end
end
