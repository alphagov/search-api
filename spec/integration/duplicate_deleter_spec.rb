require 'spec_helper'

RSpec.describe 'DuplicateDeleterTest' do
  it "can not delete when only a single document" do
    commit_document(
      "mainstream_test",
      {
        "content_id" => "3c824d6b-d982-4426-9a7d-43f2b865e77c",
        "link" => "/an-example-page",
      },
      type: "edition",
    )

    DuplicateDeleter.new('edition', io, search_config: SearchConfig.instance).call(["3c824d6b-d982-4426-9a7d-43f2b865e77c"])

    expect_log_message(msg: "as less than 2 results found")
    expect_document_present_in_rummager(id: "/an-example-page", type: "edition")
  end

  it "can delete duplicate documents on different types" do
    commit_document(
      "mainstream_test",
      {
        "content_id" => "3c824d6b-d982-4426-9a7d-43f2b865e77c",
        "link" => "/an-example-page",
      },
      type: "edition",
    )
    commit_document(
      "mainstream_test",

      {
        "content_id" => "3c824d6b-d982-4426-9a7d-43f2b865e77c",
        "link" => "/an-example-page",
      },
      type: "cma_case",
    )

    DuplicateDeleter.new('edition', io, search_config: SearchConfig.instance).call(["3c824d6b-d982-4426-9a7d-43f2b865e77c"])

    expect_log_message(msg: "Deleted duplicate for content_id")
    expect_document_present_in_rummager(id: "/an-example-page", type: "cma_case")
    expect_document_missing_in_rummager(id: "/an-example-page", type: "edition")
  end

  it "cant delete a type that doesnt exist" do
    commit_document(
      "mainstream_test",
      {
        "content_id" => "3c824d6b-d982-4426-9a7d-43f2b865e77c",
        "link" => "/an-example-page",
      },
      type: "edition",
    )
    commit_document(
      "mainstream_test",
      {
        "content_id" => "3c824d6b-d982-4426-9a7d-43f2b865e77c",
        "link" => "/an-example-page",
      },
      type: "cma_case",
    )

    DuplicateDeleter.new('ab_case', io, search_config: SearchConfig.instance).call(["3c824d6b-d982-4426-9a7d-43f2b865e77c"])

    expect_log_message(msg: "as type to delete ab_case not present in")
    expect_document_present_in_rummager(id: "/an-example-page", type: "cma_case")
    expect_document_present_in_rummager(id: "/an-example-page", type: "edition")
  end

  it "cant delete duplicate content_ids when id doesnt match" do
    commit_document(
      "mainstream_test",
      {
        "content_id" => "3c824d6b-d982-4426-9a7d-43f2b865e77c",
        "link" => "/not-an-example-page",
      },
      type: "edition",
    )
    commit_document(
      "mainstream_test",
      {
        "content_id" => "3c824d6b-d982-4426-9a7d-43f2b865e77c",
        "link" => "/an-example-page",
      },
      type: "cma_case",
    )

    DuplicateDeleter.new('edition', io, search_config: SearchConfig.instance).call(["3c824d6b-d982-4426-9a7d-43f2b865e77c"])

    expect_log_message(msg: "as multiple _id's detected")
    expect_document_present_in_rummager(id: "/not-an-example-page", type: "edition")
    expect_document_present_in_rummager(id: "/an-example-page", type: "cma_case")
  end

  it "can delete duplicate documents on different types using link" do
    commit_document(
      "mainstream_test",
      {
        "content_id" => "3c824d6b-d982-4426-9a7d-43f2b865e77c",
        "link" => "/an-example-page",
      },
      type: "edition",
    )
    commit_document(
      "mainstream_test",
      {
        "content_id" => "3c824d6b-d982-4426-9a7d-43f2b865e77c",
        "link" => "/an-example-page",
      },
      type: "cma_case",
    )

    DuplicateDeleter.new('edition', io, search_config: SearchConfig.instance).call(["/an-example-page"], id_type: "link")

    expect_log_message(msg: "Deleted duplicate for link")
    expect_document_present_in_rummager(id: "/an-example-page", type: "cma_case")
    expect_document_missing_in_rummager(id: "/an-example-page", type: "edition")
  end

  it "cant delete duplicate documents using link with different content_ids" do
    commit_document(
      "mainstream_test",
      {
        "content_id" => "aaaaaaaa-d982-4426-9a7d-43f2b865e77c",
        "link" => "/an-example-page",
      },
      type: "edition",
    )
    commit_document(
      "mainstream_test",
      {
        "content_id" => "3c824d6b-d982-4426-9a7d-43f2b865e77c",
        "link" => "/an-example-page",
      },
      type: "cma_case",
    )

    DuplicateDeleter.new('edition', io, search_config: SearchConfig.instance).call(["/an-example-page"], id_type: "link")

    expect_log_message(msg: "as multiple non-null content_id's detected")
    expect_document_present_in_rummager(id: "/an-example-page", type: "cma_case")
    expect_document_present_in_rummager(id: "/an-example-page", type: "edition")
  end

  it "can delete duplicate documents if bad item has nil content_id" do
    commit_document(
      "mainstream_test",
      { "link" => "/an-example-page" },
      type: "edition",
    )
    commit_document(
      "mainstream_test",
      {
        "content_id" => "3c824d6b-d982-4426-9a7d-43f2b865e77c",
        "link" => "/an-example-page",
      },
      type: "cma_case",
    )

    DuplicateDeleter.new('edition', io, search_config: SearchConfig.instance).call(["/an-example-page"], id_type: "link")

    expect_log_message(msg: "Deleted duplicate for link")
    expect_document_present_in_rummager(id: "/an-example-page", type: "cma_case")
    expect_document_missing_in_rummager(id: "/an-example-page", type: "edition")
  end

  it "cant delete duplicate documents if good item has nil content_id" do
    commit_document(
      "mainstream_test",
      {
        "content_id" => "3c824d6b-d982-4426-9a7d-43f2b865e77c",
        "link" => "/an-example-page",
      },
      type: "edition",
    )
    commit_document(
      "mainstream_test",
      { "link" => "/an-example-page" },
      type: "cma_case",
    )

    DuplicateDeleter.new('edition', io, search_config: SearchConfig.instance).call(["/an-example-page"], id_type: "link")

    expect_log_message(msg: "indexed with a valid '_type' but a missing content ID")
    expect_document_present_in_rummager(id: "/an-example-page", type: "cma_case")
    expect_document_present_in_rummager(id: "/an-example-page", type: "edition")
  end

  it "can delete duplicate documents on different types using link when both content_ids are missing" do
    commit_document(
      "mainstream_test",
      { "link" => "/an-example-page" },
      type: "edition",
    )
    commit_document(
      "mainstream_test",
      { "link" => "/an-example-page" },
      type: "cma_case",
    )

    DuplicateDeleter.new('edition', io, search_config: SearchConfig.instance).call(["/an-example-page"], id_type: "link")

    expect_log_message(msg: "Deleted duplicate for link")
    expect_document_present_in_rummager(id: "/an-example-page", type: "cma_case")
    expect_document_missing_in_rummager(id: "/an-example-page", type: "edition")
  end

private

  # TODO: change this to use global `expect_document_is_in_rummager` method
  def expect_document_present_in_rummager(id:, type:, index: "mainstream_test")
    doc = fetch_document_from_rummager(id: id, type: type, index: index)
    expect(doc).to be_truthy
  end

  def expect_document_missing_in_rummager(id:, type:)
    expect {
      fetch_document_from_rummager(id: id, type: type)
    }.to raise_error(Elasticsearch::Transport::Transport::Errors::NotFound)
  end

  def expect_log_message(msg:)
    io.rewind
    log = io.read
    expect(log).to include(msg), "#{msg} not in #{log}"
  end

  def io
    @io ||= StringIO.new
  end
end
