require "spec_helper"

RSpec.describe "ElasticsearchLockingTest" do
  before do
    stub_tagging_lookup
  end

  it "will not allow inserts while locked" do
    index = search_server.index_group("government_test").current
    with_lock(index) do
      expect {
        index.add([sample_document])
      }.to raise_error(SearchIndices::IndexLocked)
    end
  end

  it "will not allow updates while locked" do
    index = search_server.index_group("government_test").current
    index.add([sample_document])

    with_lock(index) do
      expect {
        index.amend(sample_document.link, "title" => "New title")
      }.to raise_error(SearchIndices::IndexLocked)
    end
  end

  it "will not allow deletes while locked" do
    index = search_server.index_group("government_test").current
    index.add([sample_document])

    with_lock(index) do
      expect {
        index.delete(sample_document.link)
      }.to raise_error(SearchIndices::IndexLocked)
    end
  end

  it "will unlock once the block is completed and allow inserts as per normal" do
    index = search_server.index_group("government_test").current
    with_lock(index) do
      # Nothing to do here
    end
    index.add([sample_document])
  end

private

  def with_lock(index)
    index.lock
    yield
    index.unlock
  end
end
