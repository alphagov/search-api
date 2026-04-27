require "spec_helper"
require "rake"

RSpec.describe "delete rake tasks" do
  before do
    task.reenable
  end

  describe "delete:by_link", type: :task do
    let(:task_name) { "delete:by_link" }
    let(:task) { Rake::Task[task_name] }
    let(:index) { SearchConfig.govuk_index_name }

    describe "when no link is provided" do
      it "prints a helpful message and exits" do
        expect {
          task.invoke(nil)
        }.to output("Missing argument. Usage: rake 'delete:by_link[link]'\n").to_stderr
                                                                             .and raise_error(SystemExit)
      end
    end

    describe "when a link is provided" do
      let(:link) { "/some-path" }

      before do
        commit_document(index, { link:, format: "guide" })
      end

      it "deletes the document from Elasticsearch" do
        expect(
          Services.elasticsearch.get(index:, id: link),
        ).to be_present

        task.invoke(link)

        expect {
          Services.elasticsearch.get(index:, id: link)
        }.to raise_error(Elasticsearch::Transport::Transport::Errors::NotFound)
      end
    end

    describe "when the document does not exist" do
      let(:link) { "/missing" }

      it "raises a not found error" do
        expect {
          task.invoke(link)
        }.to raise_error(Elasticsearch::Transport::Transport::Errors::NotFound)
      end
    end
  end

  describe "delete:by_format" do
    let(:task_name) { "delete:by_format" }
    let(:task) { Rake::Task[task_name] }
    let(:index) { SearchConfig.all_index_names.first }
    let(:format) { "answer" }

    context "when format is missing" do
      it "prints a warning" do
        expect {
          task.invoke(nil, index)
        }.to output("Specify format for deletion\n").to_stderr.and raise_error(SystemExit)
      end
    end

    context "when index_name is missing" do
      it "prints a warning" do
        expect {
          task.invoke(format, nil)
        }.to output("Specify an index\n").to_stderr.and raise_error(SystemExit)
      end
    end

    context "when there are no documents for the format" do
      it "prints no documents to delete" do
        output = capture_stdout { task.invoke(format, index) }
        expect(output).to match(/No #{format} documents to delete/)
      end
    end

    context "when there are documents for the format" do
      before do
        3.times { commit_document(index, { format: }) }
      end

      it "deletes all documents in batches" do
        output = capture_stdout do
          expect { task.invoke(format, index) }.to change {
            client.count(index:, body: { query: { term: { format: format } } })["count"]
          }.from(3).to(0)
        end

        expect(output).to match(/Deleting 3 #{format} documents/)
      end
    end
  end
end
