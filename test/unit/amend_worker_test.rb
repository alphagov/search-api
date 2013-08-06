require "test_helper"
require "elasticsearch/amend_worker"
require "failed_job_worker"

class DeleteWorkerTest < MiniTest::Unit::TestCase
  def test_amends_documents
    mock_index = mock("index")
    mock_index.expects(:amend).with("/foobang", "title" => "New title")
    Elasticsearch::SearchServer.any_instance.expects(:index)
      .with("test-index")
      .returns(mock_index)

    worker = Elasticsearch::AmendWorker.new
    worker.perform("test-index", "/foobang", "title" => "New title")
  end
end
