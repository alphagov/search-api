require "spec_helper"
require "tempfile"
require_relative "../../../support/rank_eval_test_helpers"
require_relative "../../../../lib/evaluation/rank_eval"

RSpec.describe Evaluation::RankEval do
  include RankEvalTestHelpers

  let(:evaluator) { described_class.new }

  RSpec.shared_examples "a malformed CSV row validation" do |expected_error, bad_row|
    around do |example|
      csv_data = create_malformed_csv(bad_row)
      datafile = build_datafile("malformed_csv", csv_data)
      @datafile = datafile

      example.run

      delete_datafile(datafile)
    end

    it "raises the expected validation error" do
      expect { evaluator.load_from_csv(@datafile) }.to raise_error(expected_error)
    end
  end

  describe "#load_from_csv" do
    context "when query is missing" do
      it_behaves_like "a malformed CSV row validation", "missing query for row ',/harry-potter,3\n'", [nil, "/harry-potter", 3]
    end

    context "when score is missing" do
      it_behaves_like "a malformed CSV row validation", "missing score for row 'harry potter,/harry-potter,\n'", ["harry potter", "/harry-potter", nil]
    end

    context "link is missing" do
      it_behaves_like "a malformed CSV row validation", "missing link for row 'harry potter,,3\n", ["harry potter", nil, 3]
    end

    context "when a valid csv is provided" do
      before do
        csv_data = mock_judgement_csv
        datafile = build_datafile("mock_judgement_csv", csv_data)
        @datafile = datafile
      end

      let(:expected_output) do
        {
          "harry potter" => [{ score: 3, link: "/harry-potter" }],
          "passport" => [{ score: 3, link: "/government/renew-a-passport" }],
        }
      end

      it "creates a hash of csv data" do
        hash = evaluator.load_from_csv(@datafile)
        expect(hash).to eq(expected_output)
      end
    end
  end
end
