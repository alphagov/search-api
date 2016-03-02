require "test_helper"
require "indexer/index_queue"
require "indexer/workers/bulk_index_worker"
require "indexer/workers/delete_worker"

class Indexer::IndexQueueTest < MiniTest::Unit::TestCase
  def sample_document_hashes
    %w(foo bar baz).map do |slug|
      { link: "/#{slug}", title: slug.capitalize }
    end
  end

  def test_can_queue_documents_in_bulk
    Indexer::BulkIndexWorker.expects(:perform_async)
      .with("test-index", sample_document_hashes)
    queue = Indexer::IndexQueue.new("test-index")
    queue.queue_many(sample_document_hashes)
  end

  def test_can_delete_documents
    Indexer::DeleteWorker.expects(:perform_async)
      .with("test-index", "edition", "/foobang")
    queue = Indexer::IndexQueue.new("test-index")
    queue.queue_delete("edition", "/foobang")
  end

  def test_can_amend_documents
    Indexer::AmendWorker.expects(:perform_async)
      .with("test-index", "/foobang", "title" => "Cheese")
    queue = Indexer::IndexQueue.new("test-index")
    queue.queue_amend("/foobang", "title" => "Cheese")
  end
end
