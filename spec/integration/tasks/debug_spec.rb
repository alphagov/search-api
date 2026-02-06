require "rake"

RSpec.describe "debug" do
  before { Rake::Task[task_name].reenable }

  describe "debug:show_old_index_link" do
    let(:task_name) { "debug:show_old_index_link" }
    let(:link) { "/path/to_page" }

    context "the document exists in the index" do
      it "pretty prints a document from the old indexes" do
        commit_document(
          "government_test",
          {
            "link" => link,
          },
        )

        output = capture_stdout { Rake::Task[task_name].invoke(link) }

        # check document includes expected key/value pairs
        expect(output).to include('"link"=>"/path/to_page"')
        expect(output).to include('"real_index_name"=>"government_test"')
        expect(output).to include('"_id"=>"/path/to_page"')

        # check output is multi-line (pretty-printed)
        expect(output).to include("\n")
        expect(output.lines.count).to be > 1
      end
    end

    context "the document does not exist in the index" do
      it "prints nothing" do
        output = capture_stdout { Rake::Task[task_name].invoke(link) }
        expect(output).to eq("nil\n")
      end
    end
  end

  describe "debug:show_govuk_link" do
    let(:task_name) { "debug:show_govuk_link" }
    let(:link) { "/path/to_page" }

    context "the document exists in the index" do
      it "pretty prints a document from the new content index" do
        commit_document(
          "govuk_test",
          {
            "link" => link,
          },
        )

        output = capture_stdout { Rake::Task[task_name].invoke(link) }

        # check document includes expected key/value pairs
        expect(output).to include('"link"=>"/path/to_page"')
        expect(output).to include('"real_index_name"=>"govuk_test"')
        expect(output).to include('"_id"=>"/path/to_page"')

        # check output is multi-line (pretty-printed)
        expect(output).to include("\n")
        expect(output.lines.count).to be > 1
      end
    end

    context "the document does not exist in the index" do
      it "prints nothing" do
        output = capture_stdout { Rake::Task[task_name].invoke(link) }
        expect(output).to eq("nil\n")
      end
    end
  end
end
