require "test_helper"
require "elasticsearch/document_queue"
require "elasticsearch/bulk_index_worker"

class DocumentQueueTest < MiniTest::Unit::TestCase
  def sample_document_hashes
    %w(foo bar baz).map do |slug|
      {:link => "/#{slug}", :title => slug.capitalize}
    end
  end

  def test_can_queue_documents_in_bulk
    Elasticsearch::BulkIndexWorker.expects(:perform_async)
      .with("test-index", sample_document_hashes)
    queue = Elasticsearch::DocumentQueue.new("test-index")
    queue.queue_many(sample_document_hashes)
  end
end
