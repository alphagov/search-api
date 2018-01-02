require 'spec_helper'

RSpec.describe 'ElasticsearchLockingTest' do
  before do
    stub_tagging_lookup
  end

  it "should fail to insert when index locked" do
    index = search_server.index_group(SearchConfig.instance.default_index_name).current
    with_lock(index) do
      expect {
        index.add([sample_document])
      }.to raise_error(SearchIndices::IndexLocked)
    end
  end

  it "should fail to amend when index locked" do
    index = search_server.index_group(SearchConfig.instance.default_index_name).current
    index.add([sample_document])

    with_lock(index) do
      expect {
        index.amend(sample_document.link, "title" => "New title")
      }.to raise_error(SearchIndices::IndexLocked)
    end
  end

  it "should fail to delete when index locked" do
    index = search_server.index_group(SearchConfig.instance.default_index_name).current
    index.add([sample_document])

    with_lock(index) do
      expect {
        index.delete("edition", sample_document.link)
      }.to raise_error(SearchIndices::IndexLocked)
    end
  end

  it "should unlock index" do
    index = search_server.index_group(SearchConfig.instance.default_index_name).current
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
