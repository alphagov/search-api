require "spec_helper"
require "stringio"

RSpec.describe Index::RemoteReindexer do
  let(:source_url) { "https://source:443" }
  let(:dest_url)   { "https://dest:443" }
  let(:index)      { "my_index" }
  let(:out)        { StringIO.new }

  let(:indices_client) { instance_double("Elasticsearch::API::Indices::IndicesClient") }
  let(:tasks_client)   { instance_double("Elasticsearch::API::Tasks::TasksClient") }
  let(:dest_client) do
    instance_double("ElasticsearchClient", indices: indices_client, tasks: tasks_client)
  end

  subject(:reindexer) do
    described_class.new(
      source_url: source_url,
      dest_url: dest_url,
      index: index,
      dest_client: dest_client,
      poll_interval: 0,
      out: out,
    )
  end

  describe "#initialize" do
    it "does not raise when all required args are present" do
      expect { reindexer }.not_to raise_error
    end

    it "raises MissingArguments when source_url is missing" do
      expect {
        described_class.new(source_url: nil, dest_url: dest_url, index: index, dest_client: dest_client)
      }.to raise_error(described_class::MissingArguments, /Usage: rake/)
    end

    it "raises MissingArguments when dest_url is missing" do
      expect {
        described_class.new(source_url: source_url, dest_url: nil, index: index, dest_client: dest_client)
      }.to raise_error(described_class::MissingArguments)
    end

    it "raises MissingArguments when index is missing" do
      expect {
        described_class.new(source_url: source_url, dest_url: dest_url, index: nil, dest_client: dest_client)
      }.to raise_error(described_class::MissingArguments)
    end
  end

  describe "#reindex" do
    context "when the destination index does not exist" do
      before { allow(indices_client).to receive(:exists?).with(index: index).and_return(false) }

      it "raises without attempting to reindex" do
        expect(dest_client).not_to receive(:reindex)
        expect { reindexer.reindex }.to raise_error("Destination index 'my_index' does not exist")
      end
    end

    context "when the remote index exists" do
      before do
        allow(indices_client).to receive(:exists?).with(index: index).and_return(true)
        allow(dest_client).to receive(:reindex).and_return({ "task" => "task123" })
      end

      it "kicks off the reindex with the expected request body" do
        allow(tasks_client).to receive(:get).with(task_id: "task123").and_return(
          "completed" => true,
          "response" => { "created" => 1, "updated" => 0, "failures" => [] },
        )

        reindexer.reindex

        expect(dest_client).to have_received(:reindex).with(
          body: {
            source: { remote: { host: source_url }, index: index },
            dest: { index: index },
          },
          wait_for_completion: false,
        )
      end

      context "when the task completes successfully" do
        before do
          allow(tasks_client).to receive(:get).with(task_id: "task123").and_return(
            "completed" => true,
            "response" => { "created" => 10, "updated" => 5, "failures" => [] },
          )
        end

        it "does not raise and prints a summary" do
          expect { reindexer.reindex }.not_to raise_error

          expect(out.string).to include("Reindex complete!")
          expect(out.string).to include("Created: 10")
          expect(out.string).to include("Updated: 5")
          expect(out.string).to include("Failures: 0")
        end
      end

      context "when the task completes with an error" do
        before do
          allow(tasks_client).to receive(:get).with(task_id: "task123").and_return(
            "completed" => true,
            "error" => { "type" => "some_error" },
          )
        end

        it "raises ReindexFailed" do
          expect { reindexer.reindex }.to raise_error(described_class::ReindexFailed, /some_error/)
        end
      end

      context "when the task is still in progress" do
        let(:in_progress_task) do
          {
            "completed" => false,
            "task" => {
              "status" => {
                "total" => 100,
                "created" => 20,
                "updated" => 10,
                "deleted" => 0,
                "batches" => 3,
                "version_conflicts" => 1,
              },
            },
          }
        end
        let(:completed_task) do
          { "completed" => true, "response" => { "created" => 80, "updated" => 20, "failures" => [] } }
        end

        it "polls until completion, sleeping between checks and logging progress" do
          allow(tasks_client).to receive(:get).with(task_id: "task123")
                                              .and_return(in_progress_task, completed_task)
          allow(reindexer).to receive(:sleep)

          reindexer.reindex

          expect(tasks_client).to have_received(:get).twice
          expect(reindexer).to have_received(:sleep).once.with(0)
          expect(out.string).to include("30/100 documents (30.0%)")
          expect(out.string).to include("batches=3")
          expect(out.string).to include("version_conflicts=1")
        end

        context "and the total is zero" do
          let(:zero_total_task) do
            {
              "completed" => false,
              "task" => {
                "status" => {
                  "total" => 0,
                  "created" => 0,
                  "updated" => 0,
                  "deleted" => 0,
                  "batches" => 0,
                  "version_conflicts" => 0,
                },
              },
            }
          end

          it "reports 0% instead of dividing by zero" do
            allow(tasks_client).to receive(:get).with(task_id: "task123")
                                                .and_return(zero_total_task, completed_task)
            allow(reindexer).to receive(:sleep)

            expect { reindexer.reindex }.not_to raise_error
            expect(out.string).to include("0/0 documents (0.0%)")
          end
        end
      end
    end
  end
end
