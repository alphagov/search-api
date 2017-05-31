require "integration_test_helper"
require 'duplicate_deleter'

class DuplicateDeleterTest < IntegrationTest
  def test_can_not_delete_when_only_a_single_document
    commit_document(
      "mainstream_test",
      "content_id" => "3c824d6b-d982-4426-9a7d-43f2b865e77c",
      "link" => "/an-example-page",
      "_type" => "edition",
    )

    DuplicateDeleter.new('edition', io).call(["3c824d6b-d982-4426-9a7d-43f2b865e77c"])

    assert_message(msg: "as less than 2 results found")
    assert_document_present_in_rummager(id: "/an-example-page", type: "edition")
  end

  def test_can_delete_duplicate_documents_on_different_types
    commit_document(
      "mainstream_test",
      "content_id" => "3c824d6b-d982-4426-9a7d-43f2b865e77c",
      "link" => "/an-example-page",
      "_type" => "edition",
    )
    commit_document(
      "mainstream_test",
      "content_id" => "3c824d6b-d982-4426-9a7d-43f2b865e77c",
      "link" => "/an-example-page",
      "_type" => "cma_case",
    )

    DuplicateDeleter.new('edition', io).call(["3c824d6b-d982-4426-9a7d-43f2b865e77c"])

    assert_message(msg: "Deleted duplicate for content_id")
    assert_document_present_in_rummager(id: "/an-example-page", type: "cma_case")
    assert_document_missing_in_rummager(id: "/an-example-page", type: "edition")
  end

  def test_cant_delete_a_type_that_doesnt_exist
    commit_document(
      "mainstream_test",
      "content_id" => "3c824d6b-d982-4426-9a7d-43f2b865e77c",
      "link" => "/an-example-page",
      "_type" => "edition",
    )
    commit_document(
      "mainstream_test",
      "content_id" => "3c824d6b-d982-4426-9a7d-43f2b865e77c",
      "link" => "/an-example-page",
      "_type" => "cma_case",
    )

    DuplicateDeleter.new('ab_case', io).call(["3c824d6b-d982-4426-9a7d-43f2b865e77c"])

    assert_message(msg: "as type to delete ab_case not present in")
    assert_document_present_in_rummager(id: "/an-example-page", type: "cma_case")
    assert_document_present_in_rummager(id: "/an-example-page", type: "edition")
  end

  def test_cant_delete_duplicate_content_ids_when_id_doesnt_match
    commit_document(
      "mainstream_test",
      "content_id" => "3c824d6b-d982-4426-9a7d-43f2b865e77c",
      "link" => "/not-an-example-page",
      "_type" => "edition",
    )
    commit_document(
      "mainstream_test",
      "content_id" => "3c824d6b-d982-4426-9a7d-43f2b865e77c",
      "link" => "/an-example-page",
      "_type" => "cma_case",
    )

    DuplicateDeleter.new('edition', io).call(["3c824d6b-d982-4426-9a7d-43f2b865e77c"])

    assert_message(msg: "as multiple _id's detected")
    assert_document_present_in_rummager(id: "/not-an-example-page", type: "edition")
    assert_document_present_in_rummager(id: "/an-example-page", type: "cma_case")
  end

  def test_can_delete_duplicate_content_ids_when_contact_id_is_wrong
    commit_document(
      "mainstream_test",
      "content_id" => "e3eaa461-3a85-4881-b412-9c58e7ea4ebd",
      "link" => "/contact-page",
      "_type" => "edition",
      "_id" => "/contact-page",
    )
    commit_document(
      "mainstream_test",
      "content_id" => "e3eaa461-3a85-4881-b412-9c58e7ea4ebd",
      "link" => "/contact-page",
      "_type" => "contact",
      "_id" => "contact-page",
    )

    DuplicateDeleter.new('edition', io).call(["e3eaa461-3a85-4881-b412-9c58e7ea4ebd"])

    assert_message(msg: "Deleted duplicate for content_id")
    assert_document_present_in_rummager(id: "contact-page", type: "contact")
    assert_document_missing_in_rummager(id: "/contact-page", type: "edition")
  end

  def test_can_delete_duplicate_documents_on_different_types_using_link
    commit_document(
      "mainstream_test",
      "content_id" => "3c824d6b-d982-4426-9a7d-43f2b865e77c",
      "link" => "/an-example-page",
      "_type" => "edition",
    )
    commit_document(
      "mainstream_test",
      "content_id" => "3c824d6b-d982-4426-9a7d-43f2b865e77c",
      "link" => "/an-example-page",
      "_type" => "cma_case",
    )

    DuplicateDeleter.new('edition', io).call(["/an-example-page"], id_type: "link")

    assert_message(msg: "Deleted duplicate for link")
    assert_document_present_in_rummager(id: "/an-example-page", type: "cma_case")
    assert_document_missing_in_rummager(id: "/an-example-page", type: "edition")
  end

  def test_cant_delete_duplicate_documents_using_link_with_different_content_ids
    commit_document(
      "mainstream_test",
      "content_id" => "aaaaaaaa-d982-4426-9a7d-43f2b865e77c",
      "link" => "/an-example-page",
      "_type" => "edition",
    )
    commit_document(
      "mainstream_test",
      "content_id" => "3c824d6b-d982-4426-9a7d-43f2b865e77c",
      "link" => "/an-example-page",
      "_type" => "cma_case",
    )

    DuplicateDeleter.new('edition', io).call(["/an-example-page"], id_type: "link")

    assert_message(msg: "as multiple non-null content_id's detected")
    assert_document_present_in_rummager(id: "/an-example-page", type: "cma_case")
    assert_document_present_in_rummager(id: "/an-example-page", type: "edition")
  end

  def test_can_delete_duplicate_documents_if_bad_item_has_nil_content_id
    commit_document(
      "mainstream_test",
      "link" => "/an-example-page",
      "_type" => "edition",
    )
    commit_document(
      "mainstream_test",
      "content_id" => "3c824d6b-d982-4426-9a7d-43f2b865e77c",
      "link" => "/an-example-page",
      "_type" => "cma_case",
    )

    DuplicateDeleter.new('edition', io).call(["/an-example-page"], id_type: "link")

    assert_message(msg: "Deleted duplicate for link")
    assert_document_present_in_rummager(id: "/an-example-page", type: "cma_case")
    assert_document_missing_in_rummager(id: "/an-example-page", type: "edition")
  end

  def test_cant_delete_duplicate_documents_if_good_item_has_nil_content_id
    commit_document(
      "mainstream_test",
      "content_id" => "3c824d6b-d982-4426-9a7d-43f2b865e77c",
      "link" => "/an-example-page",
      "_type" => "edition",
    )
    commit_document(
      "mainstream_test",
      "link" => "/an-example-page",
      "_type" => "cma_case",
    )

    DuplicateDeleter.new('edition', io).call(["/an-example-page"], id_type: "link")

    assert_message(msg: "indexed with a valid '_type' but a missing content ID")
    assert_document_present_in_rummager(id: "/an-example-page", type: "cma_case")
    assert_document_present_in_rummager(id: "/an-example-page", type: "edition")
  end

  def test_can_delete_duplicate_documents_on_different_types_using_link_when_both_content_ids_are_missing
    commit_document(
      "mainstream_test",
      "link" => "/an-example-page",
      "_type" => "edition",
    )
    commit_document(
      "mainstream_test",
      "link" => "/an-example-page",
      "_type" => "cma_case",
    )

    DuplicateDeleter.new('edition', io).call(["/an-example-page"], id_type: "link")

    assert_message(msg: "Deleted duplicate for link")
    assert_document_present_in_rummager(id: "/an-example-page", type: "cma_case")
    assert_document_missing_in_rummager(id: "/an-example-page", type: "edition")
  end

private

  def assert_document_present_in_rummager(id:, type:, index: "mainstream_test")
    doc = fetch_document_from_rummager(id: id, type: type, index: index)
    assert doc
  end

  def assert_document_missing_in_rummager(id:, type:)
    assert_raises Elasticsearch::Transport::Transport::Errors::NotFound do
      fetch_document_from_rummager(id: id, type: type)
    end
  end


  def assert_message(msg:)
    io.rewind
    log = io.read
    assert log.include?(msg), "#{msg} not in #{log}"
  end

  def io
    @io ||= StringIO.new
  end
end
