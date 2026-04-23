require "spec_helper"

RSpec.describe "ElasticsearchLockingTest" do
  before do
    stub_tagging_lookup
  end

  it "will not allow deletes while locked" do
    index = search_server.index_group("govuk_test").current
    commit_document("govuk_test", { "link" => "/link", "title" => "A nice title" })

    with_lock(index) do
      expect {
        index.delete("/link")
      }.to raise_error(SearchIndices::IndexLocked)
    end
  end

  it "will unlock once the block is completed and allow inserts as per normal" do
    index = search_server.index_group("govuk_test").current
    with_lock(index) do
      # Nothing to do here
    end
    commit_document("govuk_test", { "link" => "/link", "title" => "A nice title" })
  end

private

  def with_lock(index)
    index.lock
    yield
    index.unlock
  end
end
