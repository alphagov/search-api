require "rake"
require_relative "../helpers/best_bet_helpers"

RSpec.describe "debug" do
  include BestBetIntegrationTestHelpers

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

  describe "debug:show_new_synonyms" do
    let(:task_name) { "debug:show_new_synonyms" }
    let(:query) { "ten" }

    context "a document with synonyms exists in the index" do
      it "prints examples of the synonyms" do
        commit_document(
          "govuk_test",
          {
            "title" => "Number 10 Press Briefing",
            "description" => "Number 10 gives an exciting press briefing.",
          },
        )

        output = capture_stdout { Rake::Task[task_name].invoke(query) }
        output = Rainbow.uncolor(output)

        # search is looking for synonyms
        expect(output).to include("Query interpretation for 'ten':")
        expect(output).to include('"type"=>"SYNONYM"')
        # exact text is indexed as alphanumeric
        expect(output).to include("Document with this exact text is indexed as:")
        expect(output).to include('"type"=>"<ALPHANUM>"')

        expect(output).to include("Sample matches (basic query with synonyms):")
        expect(output).to include("Number 10 Press Briefing")
        expect(output).to include("Number 10 gives an exciting press briefing.")
      end
    end

    context "no document with synonyms exists in the index" do
      it "prints there were no results found" do
        output = capture_stdout { Rake::Task[task_name].invoke(query) }
        output = Rainbow.uncolor(output)

        # search is looking for synonyms
        expect(output).to include("Query interpretation for 'ten':")
        expect(output).to include('"type"=>"SYNONYM"')
        # exact text is indexed as alphanumeric
        expect(output).to include("Document with this exact text is indexed as:")
        expect(output).to include('"type"=>"<ALPHANUM>"')

        expect(output).to include("Sample matches (basic query with synonyms):")
        expect(output).to include("No results found")
      end
    end
  end

  describe "debug:fetch_best_bets" do
    let(:task_name) { "debug:fetch_best_bets" }
    let(:query) { "best bets and worst bets" }

    context "there are best and worst bets for a given query" do
      before do
        add_best_bet(
          query: "best bet",
          type: "stemmed",
          link: "/a-best-bet-link",
          position: 1,
        )
        add_worst_bet(
          query: "worst bet",
          type: "stemmed",
          link: "/a-worst-bet-link",
        )
      end

      it "prints best and worst bets for a given query" do
        output = capture_stdout { Rake::Task[task_name].invoke(query) }

        expected_output = CSV.generate do |csv|
          csv << ["best", "/a-best-bet-link", 1]
          csv << ["worst", "/a-worst-bet-link"]
        end
        expect(output).to eq(expected_output)
      end
    end

    context "there are no best or worst bets for a given query" do
      it "prints nothing" do
        output = capture_stdout { Rake::Task[task_name].invoke(query) }
        expect(output).to eq("")
      end
    end
  end
end
