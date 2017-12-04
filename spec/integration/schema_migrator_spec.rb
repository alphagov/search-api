require 'spec_helper'

RSpec.describe SchemaMigrator do
  it "switches the alias to a new index" do
    index_group = search_server.index_group("govuk_test")
    original_index = index_group.current_real

    SchemaMigrator.new("govuk_test", search_config) do |migrator|
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

    SchemaMigrator.new("govuk_test", search_config) do |migrator|
      migrator.reindex
      migrator.switch_to_new_index
    end

    expect_document_is_in_rummager(document, index: "govuk_test", id: "/a-page-to-be-reindexed")
    expect_document_is_in_rummager(document, index: original_index.real_name, id: "/a-page-to-be-reindexed")
  end

  # TODO: Test missing content
end
