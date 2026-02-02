require "spec_helper"
require "rake"

RSpec.describe "indices" do
  let(:elasticsearch_client) { double("Elasticsearch::Client") }
  let(:indices_client) do
    double("Elasticsearch::API::Indices::IndicesClient",
           get_alias: {},
           update_aliases: {},
           get: {},
           create: {},
           put_settings: {},
           delete: {},
           put_mapping: {})
  end
  let(:base_name) { index_names.first }
  let(:index_name) { base_name }
  let(:index_names) { SearchConfig.all_index_names }

  before do
    allow(Services).to receive(:elasticsearch).and_return(elasticsearch_client)
    allow(elasticsearch_client).to receive(:indices).and_return(indices_client)
    Rake::Task[task_name].reenable
  end

  around do |example|
    ClimateControl.modify(
      SEARCH_INDEX: "all",
    ) { example.run }
  end

  describe "list_indices" do
    let(:task_name) { "search:list_indices" }
    let(:index1) { "#{base_name}-2026-01-27t08-24-32z-aaaaaaaa-1111-1111-1111-aaaaaaaaaaaa" }
    let(:index2) { "#{base_name}-2026-01-27t08-24-32z-bbbbbbbb-2222-2222-2222-bbbbbbbbbbbb" }
    let(:indices) { { index1 => {}, index2 => {} } }
    let(:aliases) do
      { index1 => { "aliases" => { base_name => {} } } }
    end

    before do
      allow(indices_client).to receive(:get).with(index: "#{base_name}*", expand_wildcards: %w[open]).and_return(indices)
      allow(indices_client).to receive(:get_alias).with(index: base_name).and_return(aliases)
    end

    it "lists only the active index by default" do
      output = capture_stdout do
        Rake::Task[task_name].invoke
      end
      expect(output).to include("CLUSTER A")
      expect(output).to include("#{base_name}:")
      expect(output).to include("* #{index1}")
      expect(output).to_not include(index2)
    end

    it "lists all indices when [all] is passed" do
      output = capture_stdout do
        Rake::Task[task_name].invoke("all")
      end
      expect(output).to include("CLUSTER A")
      expect(output).to include("#{base_name}:")
      expect(output).to include("* #{index1}")
      expect(output).to include("  #{index2}")
    end
  end

  describe "create_all_indices" do
    let(:task_name) { "search:create_all_indices" }
    it "creates all indices" do
      Rake::Task[task_name].invoke
      index_names.each do |index_name|
        expect(indices_client).to have_received(:create)
                                    .with(
                                      hash_including(
                                        index: start_with(index_name),
                                        body: kind_of(Hash),
                                      ),
                                    )
      end
    end
    it "switches to the newly created index if it doesn't exist" do
      Rake::Task[task_name].invoke
      index_names.each do |index_name|
        expect(indices_client).to have_received(:update_aliases)
          .with(body: hash_including("actions" => array_including("add" => hash_including("index" => start_with(index_name),
                                                                                          "alias" => index_name))))
      end
    end
  end

  describe "create_index" do
    let(:task_name) { "search:create_index" }
    it "creates index" do
      Rake::Task[task_name].invoke(base_name)
      expect(indices_client).to have_received(:create).once
      expect(indices_client).to have_received(:create)
                                  .with(
                                    hash_including(
                                      index: start_with(base_name),
                                      body: kind_of(Hash),
                                    ),
                                  )
    end
    it "switches to the newly created index if it doesn't exist" do
      Rake::Task[task_name].invoke(base_name)
      expect(indices_client).to have_received(:update_aliases).once
      expect(indices_client).to have_received(:update_aliases)
        .with(body: hash_including("actions" => array_including("add" => hash_including("index" => start_with(base_name),
                                                                                        "alias" => base_name))))
    end
  end

  RSpec.shared_examples "index lock toggle" do |task_name:, locked:|
    let(:task_name) { task_name }
    let(:body) do
      {
        "index" => {
          "blocks" => {
            "read_only_allow_delete" => locked,
          },
        },
      }
    end

    it "#{locked ? 'locks' : 'unlocks'} all indices" do
      Rake::Task[task_name].invoke

      index_names.each do |index_name|
        expect(indices_client).to have_received(:put_settings)
                                    .with(body:, index: index_name)
      end
    end
  end

  describe "lock" do
    it_behaves_like "index lock toggle",
                    task_name: "search:lock",
                    locked: true
  end

  describe "unlock" do
    it_behaves_like "index lock toggle",
                    task_name: "search:unlock",
                    locked: false
  end

  describe "search:update_popularity" do
    let(:task_name) { "search:update_popularity" }

    shared_examples "updates popularity" do |process_all|
      it "updates popularity for all indices (process_all=#{process_all})" do
        allow(GovukIndex::PopularityUpdater).to receive(:update)

        Rake::Task[task_name].invoke

        index_names.each do |index_name|
          expect(GovukIndex::PopularityUpdater).to have_received(:update)
                                                     .with(index_name, process_all:)
        end
      end
    end

    context "when PROCESS_ALL_DATA is not set" do
      it_behaves_like "updates popularity", false
    end

    context "when PROCESS_ALL_DATA is set" do
      around do |example|
        ClimateControl.modify(PROCESS_ALL_DATA: "1") { example.run }
      end

      it_behaves_like "updates popularity", true
    end
  end

  describe "search:update_supertypes" do
    let(:task_name) { "search:update_supertypes" }

    it "updates supertypes for all indices" do
      allow(GovukIndex::SupertypeUpdater).to receive(:update)

      Rake::Task[task_name].invoke

      index_names.each do |index_name|
        expect(GovukIndex::SupertypeUpdater).to have_received(:update)
                                                  .with(index_name)
      end
    end
  end

  describe "search:migrate_schema" do
    let(:task_name) { "search:migrate_schema" }
    let(:cluster) { Clusters.active.first }

    def stub_migrator(index_name, failed: false)
      instance_double(SchemaMigrator, reindex: nil, switch_to_new_index: nil, failed:).tap do |migrator|
        allow(SchemaMigrator).to receive(:new)
                                   .with(index_name, cluster:)
                                   .and_return(migrator)
      end
    end

    context "when all indices migrate successfully" do
      it "reindexes and switches aliases for all indices" do
        migrators = index_names.map do |index_name|
          stub_migrator(index_name)
        end

        output = capture_stdout { Rake::Task[task_name].invoke }

        migrators.each do |migrator|
          expect(migrator).to have_received(:reindex)
          expect(migrator).to have_received(:switch_to_new_index)
        end

        expect(output).to include("Migrating schema on cluster A")
      end
    end

    context "when one or more indices fail to migrate" do
      it "raises an error listing the failed indices and does not switch them" do
        failed_index_name = index_names.first
        successful_index_names = index_names - [failed_index_name]

        failed_migrator = stub_migrator(failed_index_name, failed: true)
        successful_migrators = successful_index_names.map do |index_name|
          stub_migrator(index_name)
        end

        expect {
          capture_stdout { Rake::Task[task_name].invoke }
        }.to raise_error(RuntimeError, "Failure during reindexing for: #{failed_index_name}")

        successful_migrators.each do |migrator|
          expect(migrator).to have_received(:reindex)
          expect(migrator).to have_received(:switch_to_new_index)
        end
        expect(failed_migrator).to have_received(:reindex)
        expect(failed_migrator).not_to have_received(:switch_to_new_index)
      end
    end
  end

  describe "search:update_schema" do
    let(:task_name) { "search:update_schema" }
    let(:cluster)   { Clusters.active.first }

    def type(index_name)
      SearchConfig.instance(cluster).search_server.index_group(index_name).current.mappings.keys.first
    end

    it "updates schema for all indices and reports successes and failures" do
      output = capture_stdout { Rake::Task[task_name].invoke }

      expect(output).to include("Updating schema on cluster A")

      index_names.each do |index_name|
        expect(indices_client).to have_received(:put_mapping).with(index: index_name, type: type(index_name), body: kind_of(Hash))
        expect(output).to include("Successfully synchronised #{type(index_name)} type on #{index_name} index")
      end
    end
    it "reports failures" do
      failed_index_name = index_names.first
      allow(indices_client).to receive(:put_mapping)
        .with(index: failed_index_name, type: type(failed_index_name), body: kind_of(Hash))
        .and_raise(Elasticsearch::Transport::Transport::Errors::BadRequest.new("test error"))

      output = capture_stdout { Rake::Task[task_name].invoke }
      expect(output).to include("Unable to synchronise #{type(failed_index_name)} on #{failed_index_name} due to test error")
    end
  end

  describe "switch_to_named_index" do
    let(:task_name) { "search:switch_to_named_index" }
    let(:cluster)   { Clusters.active.first }
    it "switches to the named index" do
      output = capture_stdout { Rake::Task[task_name].invoke(index_name) }
      expect(indices_client).to have_received(:update_aliases)
        .with(body: hash_including("actions" => array_including("add" => hash_including("index" => start_with(index_name),
                                                                                        "alias" => index_name))))
      expect(output).to include("Switching #{index_name} -> #{index_name}")
    end
    it "needs an argument" do
      expect { Rake::Task[task_name].invoke }.to raise_error(StandardError, /The new index name must be supplied/)
    end
  end

  describe "clean" do
    let(:task_name) { "search:clean" }
    let(:index_current) { "#{base_name}-2026-01-27t08-24-32z-aaaaaaaa-1111-1111-1111-aaaaaaaaaaaa" }
    let(:index_not_current) { "#{base_name}-2024-01-27t08-24-32z-aaaaaaaa-1111-1111-1111-aaaaaaaaaaaa" }
    let(:aliases) do
      { index_current => { "aliases" => { base_name => {} } },
        index_not_current => { "aliases" => {} } }
    end
    before do
      allow(indices_client).to receive(:get).with(index: "#{base_name}*", expand_wildcards: kind_of(Array)).and_return(aliases)
    end
    it "deletes all but the 'current' index" do
      Rake::Task[task_name].invoke
      expect(indices_client).to have_received(:delete).with(index: index_not_current)
    end
  end

  describe "timed_clean" do
    let(:task_name) { "search:timed_clean" }
    let(:index_current) { "#{base_name}-2026-01-27t08-24-32z-aaaaaaaa-1111-1111-1111-aaaaaaaaaaaa" }
    let(:index_oldest) { "#{base_name}-2024-01-27t08-24-32z-aaaaaaaa-1111-1111-1111-aaaaaaaaaaaa" }
    let(:index_next_most_recent) { "#{base_name}-2025-01-27t08-24-32z-aaaaaaaa-1111-1111-1111-aaaaaaaaaaaa" }
    let(:updated_at) { "2026-01-27T08:24:32Z" }
    let(:max_index_age) { 3 }

    let(:aliases) do
      { index_current => { "aliases" => { base_name => {} } },
        index_oldest => { "aliases" => {} },
        index_next_most_recent => { "aliases" => {} } }
    end

    around do |example|
      ClimateControl.modify(
        MAX_INDEX_AGE: max_index_age.to_s,
      ) { example.run }
    end

    before do
      allow(indices_client).to receive(:get).with(index: "#{base_name}*", expand_wildcards: %w[open closed]).and_return(aliases)
      allow(elasticsearch_client).to receive(:search).and_return(
        { "hits" => { "hits" => [{ "_source" => { "updated_at" => updated_at } }] } },
      )
    end
    it "deletes all but the 'current' index and the next most recent index" do
      Rake::Task[task_name].invoke
      expect(indices_client).to have_received(:delete).with(index: index_oldest)
      expect(indices_client).to_not have_received(:delete).with(index: index_next_most_recent)
      expect(indices_client).to_not have_received(:delete).with(index: index_current)
    end
    it "does not delete any index because all indices have recently been updated" do
      Timecop.freeze(updated_at.to_time) do
        Rake::Task[task_name].invoke
      end
      expect(indices_client).not_to have_received(:delete)
    end
    it "deletes indices that have not been updated for 'max_index_age' days" do
      Timecop.freeze(updated_at.to_time + max_index_age.days) do
        Rake::Task[task_name].invoke
      end
      expect(indices_client).to have_received(:delete).with(index: index_oldest)
      expect(indices_client).to_not have_received(:delete).with(index: index_next_most_recent)
      expect(indices_client).to_not have_received(:delete).with(index: index_current)
    end
  end

  describe "check_recovery" do
    let(:task_name) { "search:check_recovery" }
    before do
      recovery = { index_name => { "shards" => [{ "stage" => "DONE" }, { "stage" => "DONE" }] } }
      allow(indices_client).to receive(:recovery).with(index: index_name).and_return(recovery)
    end
    it "checks recovery for all indices" do
      output = capture_stdout { Rake::Task[task_name].invoke(index_name) }
      expect(indices_client).to have_received(:recovery).with(index: index_name)

      expect(output).to include("Recovery status of #{index_name} on cluster A")
      expect(output).to include("true")
    end
    it "needs an argument" do
      expect { Rake::Task[task_name].invoke }.to raise_error(StandardError, /An 'index_name' must be supplied/)
    end
  end

  def capture_stdout
    old = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old
  end
end
