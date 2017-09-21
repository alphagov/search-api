require 'test_helper'

class ChangeNotificationProcessorTest < Minitest::Test
  def test_rejects_base_pathless_documents
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

  def test_rejects_invalid_documents
    message_payload = {}

    result = Indexer::ChangeNotificationProcessor.trigger(message_payload)

    assert_equal(:rejected, result)
  end

  def test_rejects_missing_documents
    message_payload = {
      "content_id" => "4711fc53-673a-4211-bae6-e0a3d3afd82f",
      "base_path" => "/does-not-exist",
      "document_type" => "publication",
      "title" => "How to care for your rabbit",
      "update_type" => nil,
      "publishing_app" => "whitehall"
    }

    index_mock = mock
    index_mock.stubs(:get_document_by_link).with("/does-not-exist").returns(nil)
    IndexFinder.expects(:content_index).returns(index_mock)

    result = Indexer::ChangeNotificationProcessor.trigger(message_payload)

    assert_equal(:rejected, result)
  end

  def test_accepts_existing_documents
    message_payload = {
      "content_id" => "4711fc53-673a-4211-bae6-e0a3d3afd82f",
      "base_path" => "/does-exist",
      "document_type" => "publication",
      "title" => "How to care for your rabbit",
      "update_type" => nil,
      "publishing_app" => "whitehall"
    }

    index_mock = mock
    index_mock.stubs(:get_document_by_link).with("/does-exist").returns({ "link" => "/does-exist" })
    IndexFinder.expects(:content_index).returns(index_mock)

    result = Indexer::ChangeNotificationProcessor.trigger(message_payload)

    assert_equal(:accepted, result)
  end
end
