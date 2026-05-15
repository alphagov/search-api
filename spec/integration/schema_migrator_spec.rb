require "spec_helper"

RSpec.describe SchemaMigrator do
  after do
    # reset indices
    IndexHelpers.clean_all
    IndexHelpers.create_all
  end

  it "switches the alias to a new index" do
    index_group = search_server.index_group("govuk_test")
    original_index = index_group.current_real

    migrator = described_class.new("govuk_test", wait_between_task_list_check: 0.2, io: StringIO.new)
    migrator.reindex
    migrator.switch_to_new_index

    expect(index_group.current_real.real_name).not_to eq(original_index.real_name)
  end

  it "copies data to the new index" do
    index_group = search_server.index_group("govuk_test")
    original_index = index_group.current_real

    document = {
      "link" => "/a-page-to-be-reindexed",
      "title" => "A page to be reindexed",
    }
    commit_document("govuk_test", document)

    migrator = described_class.new("govuk_test", wait_between_task_list_check: 0.2)
    migrator.reindex
    migrator.switch_to_new_index

    expect_document_is_in_rummager(document, index: "govuk_test", id: "/a-page-to-be-reindexed")
    expect_document_is_in_rummager(document, index: original_index.real_name, id: "/a-page-to-be-reindexed", clusters: [Clusters.default_cluster])
  end

  context "reindex failure" do
    it "identifies when reindexing has failed" do
      migrator = described_class.new("govuk_test", wait_between_task_list_check: 0.2, io: StringIO.new)
      dest_index = migrator.dest_index
      dest_index.close
      migrator.reindex

      expect(migrator.failed).to eq(true)
      # reopen index after test, to stop other tests failing
      dest_index.open
    end
  end
end
