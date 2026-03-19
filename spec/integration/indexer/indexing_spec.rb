require "spec_helper"

RSpec.describe "ElasticsearchIndexingTest" do
  include GdsApi::TestHelpers::PublishingApi

  let(:sample_document) do
    {
      "title" => "TITLE",
      "description" => "DESCRIPTION",
      "format" => "answer",
      "link" => "/an-example-answer",
      "indexable_content" => "HERE IS SOME CONTENT",
    }
  end

  let(:index_name) { "government_test" }

  before do
    stub_tagging_lookup
    with_just_one_cluster
  end

  it_behaves_like "govuk and detailed index protection", "/:index/documents", method: :post
  it_behaves_like "rejects unknown index", "/unknown_index/documents", method: :post

  it "adds a document to the search index" do
    stub_publishing_api_has_expanded_links(
      {
        content_id: "6b965b82-2e33-4587-a70c-60204cbb3e29",
        expanded_links: {},
      },
      with_drafts: false,
    )

    post "/government_test/documents",
         {
           "_type" => "edition",
           "content_id" => "6b965b82-2e33-4587-a70c-60204cbb3e29",
           "title" => "TITLE",
           "format" => "answer",
           "content_store_document_type" => "answer",
           "link" => "/an-example-answer",
           "indexable_content" => "HERE IS SOME CONTENT",
           "licence_identifier" => "1201-5-1",
           "licence_short_description" => "A short description of a licence",
         }.to_json

    expect_document_is_in_rummager(
      {
        "content_id" => "6b965b82-2e33-4587-a70c-60204cbb3e29",
        "title" => "TITLE",
        "format" => "answer",
        "link" => "/an-example-answer",
        "indexable_content" => "HERE IS SOME CONTENT",
        "email_document_supertype" => "other",
        "user_journey_document_supertype" => "thing",
        "government_document_supertype" => "other",
        "content_purpose_supergroup" => "services",
        "content_purpose_subgroup" => "transactions",
        "licence_identifier" => "1201-5-1",
        "licence_short_description" => "A short description of a licence",
      },
      type: "edition",
      index: "government_test",
    )
  end

  it "defaults the type to 'edition' if not specified" do
    stub_publishing_api_has_expanded_links(
      {
        content_id: "9d86d339-44c2-474f-8daf-cb64bed6c0d9",
        expanded_links: {},
      },
      with_drafts: false,
    )

    post "/government_test/documents",
         {
           "content_id" => "9d86d339-44c2-474f-8daf-cb64bed6c0d9",
           "link" => "/an-example-answer",
         }.to_json

    expect_document_is_in_rummager(
      {
        "content_id" => "9d86d339-44c2-474f-8daf-cb64bed6c0d9",
        "link" => "/an-example-answer",
      },
      type: "edition",
      index: "government_test",
    )
  end

  it "indexes start and end dates" do
    post "/government_test/documents",
         {
           "title" => "TITLE",
           "format" => "topical_event",
           "slug" => "/government/topical-events/foo",
           "link" => "/government/topical-events/foo",
           "start_date" => "2016-01-01T00:00:00Z",
           "end_date" => "2017-01-01T00:00:00Z",
           "logo_formatted_title" => 'The\nTitle',
           "organisation_brand" => "cabinet-office",
           "organisation_crest" => "single-identity",
           "logo_url" => "http://url/to/logo.png",
         }.to_json

    expect_document_is_in_rummager(
      {
        "title" => "TITLE",
        "format" => "topical_event",
        "slug" => "/government/topical-events/foo",
        "link" => "/government/topical-events/foo",
        "start_date" => "2016-01-01T00:00:00Z",
        "end_date" => "2017-01-01T00:00:00Z",
        "logo_formatted_title" => 'The\nTitle',
        "organisation_brand" => "cabinet-office",
        "organisation_crest" => "single-identity",
        "logo_url" => "http://url/to/logo.png",
      },
      index: "government_test",
    )
  end

  it "tags organisation pages to themselves, so that filtering on an organisation returns the homepage" do
    post "/government_test/documents",
         {
           "title" => "HMRC",
           "link" => "/government/organisations/hmrc",
           "slug" => "hmrc",
           "format" => "organisation",
           "organisations" => [],
         }.to_json

    expect_document_is_in_rummager(
      {
        "link" => "/government/organisations/hmrc",
        "organisations" => %w[hmrc],
      },
      index: "government_test",
    )
  end

  it "returns a 202 (queued) response" do
    post "/government_test/documents", sample_document.to_json

    expect(last_response.status).to eq(202)
    expect_document_is_in_rummager(sample_document, index: "government_test")
  end

  context "when indexing to the metasearch index" do
    let(:index_name) { "metasearch_test" }

    it "reschedules the job if the index has a write lock" do
      details = <<~DETAILS
        {\"best_bets\":[
          {\"link\":\"/learn-to-drive-a-car\",\"position\":1},
          {\"link\":\"/learn-to-drive-a-car\",\"position\":3},
          {\"link\":\"/learn-to-drive-a-car\",\"position\":10}
        ],\"worst_bets\":[]}", "stemmed_query_as_term"=>" learn to drive "}]
      DETAILS
      index = search_server.index_group(index_name).current

      Sidekiq::Testing.fake! do
        # Step 1: enqueue job via request
        post "/#{index_name}/documents",
             {
               "_id" => "learn+to+drive-exact",
               "_type" => "best_bet",
               "stemmed_query" => "learn to drive",
               "details" => details,
             }.to_json

        # Step 2: run FIRST attempt while locked
        with_lock(index) do
          expect {
            Indexer::BulkIndexJob.perform_one
          }.to_not change(Indexer::BulkIndexJob.jobs, :size) # it rescheduled itself
        end

        # At this point:
        # - First job ran
        # - It hit the lock
        # - It enqueued a retry

        # Step 3: run retry AFTER unlock
        expect {
          Indexer::BulkIndexJob.drain
        }.to change(Indexer::BulkIndexJob.jobs, :size).by(-1)

        # Step 4: assert success
        expect_document_is_in_rummager(
          {
            "stemmed_query" => "learn to drive",
            "details" => details,
          },
          index: index_name,
          type: "best_bet",
          id: "learn+to+drive-exact",
        )
      end
    end
  end
end
