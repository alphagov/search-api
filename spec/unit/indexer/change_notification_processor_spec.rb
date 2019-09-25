require "spec_helper"

RSpec.describe Indexer::ChangeNotificationProcessor do
  it "rejects base_pathless documents" do
    message_payload = {
      "content_id" => "4711fc53-673a-4211-bae6-e0a3d3afd82f",
      "base_path" => nil,
      "document_type" => "contact",
      "title" => "Mr Contact",
      "update_type" => nil,
      "publishing_app" => "whitehall"
    }

    result = described_class.trigger(message_payload)

    expect(:rejected).to eq(result)
  end

  it "rejects invalid documents" do
    message_payload = {}

    result = described_class.trigger(message_payload)

    expect(:rejected).to eq(result)
  end

  it "rejects missing documents" do
    message_payload = {
      "content_id" => "4711fc53-673a-4211-bae6-e0a3d3afd82f",
      "base_path" => "/does-not-exist",
      "document_type" => "publication",
      "title" => "How to care for your rabbit",
      "update_type" => nil,
      "publishing_app" => "whitehall"
    }

    index_mock = double
    allow(index_mock).to receive(:get_document_by_link).with("/does-not-exist").and_return(nil)
    expect(IndexFinder).to receive(:content_index).and_return(index_mock)

    result = described_class.trigger(message_payload)

    expect(:rejected).to eq(result)
  end

  it "accepts existing documents" do
    message_payload = {
      "content_id" => "4711fc53-673a-4211-bae6-e0a3d3afd82f",
      "base_path" => "/does-exist",
      "document_type" => "publication",
      "title" => "How to care for your rabbit",
      "update_type" => nil,
      "publishing_app" => "whitehall"
    }

    index_mock = double
    allow(index_mock).to receive(:get_document_by_link).with("/does-exist").and_return(
      "link" => "/does-exist",
      "real_index_name" => "index_name-123",
      "_id" => "document_id_345"
    )
    expect(IndexFinder).to receive(:content_index).and_return(index_mock)

    expect(Indexer::AmendWorker).to receive(:perform_async).with("index_name-123", "document_id_345", {})
    result = described_class.trigger(message_payload)

    expect(:accepted).to eq(result)
  end
end
