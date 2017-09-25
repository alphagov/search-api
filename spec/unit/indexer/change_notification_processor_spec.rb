require 'spec_helper'

RSpec.describe 'ChangeNotificationProcessorTest' do
  it "rejects_base_pathless_documents" do
    message_payload = {
      "content_id" => "4711fc53-673a-4211-bae6-e0a3d3afd82f",
      "base_path" => nil,
      "document_type" => "contact",
      "title" => "Mr Contact",
      "update_type" => nil,
      "publishing_app" => "whitehall"
    }

    result = Indexer::ChangeNotificationProcessor.trigger(message_payload)

    assert_equal(:rejected, result)
  end

  it "rejects_invalid_documents" do
    message_payload = {}

    result = Indexer::ChangeNotificationProcessor.trigger(message_payload)

    assert_equal(:rejected, result)
  end

  it "rejects_missing_documents" do
    message_payload = {
      "content_id" => "4711fc53-673a-4211-bae6-e0a3d3afd82f",
      "base_path" => "/does-not-exist",
      "document_type" => "publication",
      "title" => "How to care for your rabbit",
      "update_type" => nil,
      "publishing_app" => "whitehall"
    }

    index_mock = double
    index_mock.stub(:get_document_by_link).with("/does-not-exist").and_return(nil)
    expect(IndexFinder).to receive(:content_index).and_return(index_mock)

    result = Indexer::ChangeNotificationProcessor.trigger(message_payload)

    assert_equal(:rejected, result)
  end

  it "accepts_existing_documents" do
    message_payload = {
      "content_id" => "4711fc53-673a-4211-bae6-e0a3d3afd82f",
      "base_path" => "/does-exist",
      "document_type" => "publication",
      "title" => "How to care for your rabbit",
      "update_type" => nil,
      "publishing_app" => "whitehall"
    }

    index_mock = double
    index_mock.stub(:get_document_by_link).with("/does-exist").and_return(
      "link" => "/does-exist",
      "real_index_name" => "index_name-123",
      "_id" => "document_id_345"
    )
    expect(IndexFinder).to receive(:content_index).and_return(index_mock)

    expect(Indexer::AmendWorker).to receive(:perform_async).with("index_name-123", "document_id_345", {})
    result = Indexer::ChangeNotificationProcessor.trigger(message_payload)

    assert_equal(:accepted, result)
  end
end
