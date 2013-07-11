require "test_helper"
require "elasticsearch/bulk_index_worker"

class BulkIndexWorkerTest < MiniTest::Unit::TestCase
  def sample_document_hashes
    %w(foo bar baz).map do |slug|
      {:link => "/#{slug}", :title => slug.capitalize}
    end
  end

  def test_indexes_documents
    mock_index = mock("index")
    mock_index.expects(:bulk_index).with(sample_document_hashes)
    Elasticsearch::SearchServer.any_instance.expects(:index)
      .with("test-index")
      .returns(mock_index)

    worker = Elasticsearch::BulkIndexWorker.new
    worker.perform("test-index", sample_document_hashes)
  end
end
