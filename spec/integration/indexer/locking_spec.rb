require 'spec_helper'

RSpec.describe 'ElasticsearchLockingTest', tags: ['integration'] do
  before do
    stub_tagging_lookup
  end

  it "should_fail_to_insert_when_index_locked" do
    index = search_server.index_group(TestIndexHelpers::DEFAULT_INDEX_NAME).current
    with_lock(index) do
      assert_raises SearchIndices::IndexLocked do
        index.add([sample_document])
      end
    end
  end

  it "should_fail_to_amend_when_index_locked" do
    index = search_server.index_group(TestIndexHelpers::DEFAULT_INDEX_NAME).current
    index.add([sample_document])

    with_lock(index) do
      assert_raises SearchIndices::IndexLocked do
        index.amend(sample_document.link, "title" => "New title")
      end
    end
  end

  it "should_fail_to_delete_when_index_locked" do
    index = search_server.index_group(TestIndexHelpers::DEFAULT_INDEX_NAME).current
    index.add([sample_document])

    with_lock(index) do
      assert_raises SearchIndices::IndexLocked do
        index.delete("edition", sample_document.link)
      end
    end
  end

  it "should_unlock_index" do
    index = search_server.index_group(TestIndexHelpers::DEFAULT_INDEX_NAME).current
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
