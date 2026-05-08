require "spec_helper"

RSpec.describe SchemaMigrator do
  before do
    clean_index_content("govuk_test")
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

    described_class.new("govuk_test", wait_between_task_list_check: 0.2) do |migrator|
      migrator.reindex
      migrator.switch_to_new_index
    end

    expect_document_is_in_rummager(document, index: "govuk_test", id: "/a-page-to-be-reindexed")
    expect_document_is_in_rummager(document, index: original_index.real_name, id: "/a-page-to-be-reindexed", clusters: [Clusters.default_cluster])
  end

  context "reindex failure" do
    let(:elasticsearch_client) { instance_double("Elasticsearch::Transport::Client") }

    index_alias = {
      "govuk_test-2026-05-08t16-20-17z-dde94b44-042f-425b-aa24-d2cea8fb493f" => {
        "aliases" => {
          "govuk_test" => {},
        },
      },
    }

    failed_reindex_response = {
      "took" => 1,
      "timed_out" => false,
      "total" => 0,
      "updated" => 0,
      "created" => 0,
      "deleted" => 0,
      "batches" => 0,
      "version_conflicts" => 0,
      "noops" => 0,
      "retries" => { "bulk" => 0, "search" => 0 },
      "throttled_millis" => 0,
      "requests_per_second" => -1.0,
      "throttled_until_millis" => 0,
      "failures" => %w[test],
    }

    before do
      allow(Services).to receive(:elasticsearch).and_return(elasticsearch_client)
      allow(elasticsearch_client).to receive_message_chain(:indices, :put_settings).and_return({ "acknowledged" => true })
      allow(elasticsearch_client).to receive_message_chain(:indices, :get_alias).and_return(index_alias)
      allow(elasticsearch_client).to receive_message_chain(:indices, :create).and_return(anything)
      allow(elasticsearch_client).to receive_message_chain(:tasks, :list).with(anything).and_return({ "nodes" => {} })
      allow(elasticsearch_client).to receive(:reindex).with(anything).and_return(failed_reindex_response)
    end

    it "identifies when reindexing has failed" do
      migrator = described_class.new("govuk_test", wait_between_task_list_check: 0.2, io: StringIO.new)

      migrator.reindex

      expect(migrator.failed).to eq(true)
    end
  end
end
