require 'spec_helper'

RSpec.describe SchemaMigrator do
  before(:each) do
    clean_index_content("govuk_test")
  end

  it "switches the alias to a new index" do
    index_group = search_server.index_group("govuk_test")
    original_index = index_group.current_real

    SchemaMigrator.new("govuk_test", search_config, wait_between_task_list_check: 0.2, io: StringIO.new) do |migrator|
      migrator.reindex
      migrator.switch_to_new_index
    end

    expect(index_group.current_real.real_name).not_to eq(original_index.real_name)
  end

  it "copies data to the new index" do
    index_group = search_server.index_group("govuk_test")
    original_index = index_group.current_real

    document = {
      "link" => "/a-page-to-be-reindexed",
      "title" => "A page to be reindexed"
    }
    commit_document("govuk_test", document)

    SchemaMigrator.new("govuk_test", search_config, wait_between_task_list_check: 0.2) do |migrator|
      migrator.reindex
      migrator.switch_to_new_index
    end

    expect_document_is_in_rummager(document, index: "govuk_test", id: "/a-page-to-be-reindexed")
    expect_document_is_in_rummager(document, index: original_index.real_name, id: "/a-page-to-be-reindexed")
  end

  context "index comparison" do
    it "identifies when content has not changed" do
      commit_document("govuk_test", { "link" => "/a-page-to-be-reindexed" })

      SchemaMigrator.new("govuk_test", search_config, wait_between_task_list_check: 0.2, io: StringIO.new) do |migrator|
        migrator.reindex

        expect(migrator).not_to be_changed
      end
    end

    it "finds added content" do
      commit_document("govuk_test", { "link" => "/a-page-to-be-reindexed" })

      SchemaMigrator.new("govuk_test", search_config, wait_between_task_list_check: 0.2, io: StringIO.new) do |migrator|
        migrator.reindex

        search_server.index_group("govuk_test").current_real.unlock
        commit_document("govuk_test", { "link" => "/another-page" })

        expect(migrator).to be_changed
      end
    end

    it "finds removed content" do
      commit_document("govuk_test", { "link" => "/a-page-to-be-reindexed" }, type: "edition")

      SchemaMigrator.new("govuk_test", search_config, wait_between_task_list_check: 0.2, io: StringIO.new) do |migrator|
        migrator.reindex

        search_server.index_group("govuk_test").current_real.unlock
        client.delete(index: "govuk_test", id: "/a-page-to-be-reindexed", type: "generic-document", refresh: true)

        expect(migrator).to be_changed
      end
    end

    it "finds updated content" do
      commit_document(
        "govuk_test",
        { "link" => "/some-page", "title" => "Original title" }
      )

      SchemaMigrator.new("govuk_test", search_config, wait_between_task_list_check: 0.2, io: StringIO.new) do |migrator|
        migrator.reindex

        search_server.index_group("govuk_test").current_real.unlock
        update_document(
          "govuk_test",
          { "link" => "/some-page", "title" => "New title" }
        )

        expect(migrator).to be_changed
      end
    end
  end
end
