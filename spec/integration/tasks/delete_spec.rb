require "spec_helper"
require "rake"

RSpec.describe "delete:by_format" do
  let(:task_name) { "delete:by_format" }
  let(:task) { Rake::Task[task_name] }
  let(:index) { SearchConfig.all_index_names.first }
  let(:format) { "answer" }

  before do
    task.reenable
  end

  context "when format is missing" do
    it "prints a warning" do
      output = capture_stdout { task.invoke(nil, index) }
      expect(output).to match(/Specify format for deletion/)
    end
  end

  context "when index_name is missing" do
    it "prints a warning" do
      output = capture_stdout { task.invoke(format, nil) }
      expect(output).to match(/Specify an index/)
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
