require 'spec_helper'

RSpec.describe 'DuplicateDeleterTest' do
  it "can_not_delete_when_only_a_single_document" do
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

  it "can_delete_duplicate_documents_on_different_types" do
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

  it "cant_delete_a_type_that_doesnt_exist" do
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

  it "cant_delete_duplicate_content_ids_when_id_doesnt_match" do
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

  it "can_delete_duplicate_content_ids_when_contact_id_is_wrong" do
    commit_document(
      "mainstream_test",
      {
        "content_id" => "e3eaa461-3a85-4881-b412-9c58e7ea4ebd",
        "link" => "/contact-page",
      },
      id: "contact-page",
      type: "contact",
    )
    commit_document(
      "mainstream_test",
      {
        "content_id" => "e3eaa461-3a85-4881-b412-9c58e7ea4ebd",
        "link" => "/contact-page",
      },
      id: "/contact-page",
      type: "edition",
    )

    DuplicateDeleter.new('edition', io, search_config: SearchConfig.instance).call(["e3eaa461-3a85-4881-b412-9c58e7ea4ebd"])

    expect_log_message(msg: "Deleted duplicate for content_id")
    expect_document_present_in_rummager(id: "contact-page", type: "contact")
    expect_document_missing_in_rummager(id: "/contact-page", type: "edition")
  end

  it "can_delete_duplicate_documents_on_different_types_using_link" do
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

  it "cant_delete_duplicate_documents_using_link_with_different_content_ids" do
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

  it "can_delete_duplicate_documents_if_bad_item_has_nil_content_id" do
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

  it "cant_delete_duplicate_documents_if_good_item_has_nil_content_id" do
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

  it "can_delete_duplicate_documents_on_different_types_using_link_when_both_content_ids_are_missing" do
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
