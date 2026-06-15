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
      it_behaves_like "a malformed CSV row validation", "missing query for row ',harry-potter-content-id,3\n'", [nil, "harry-potter-content-id", 3]
    end

    context "when score is missing" do
      it_behaves_like "a malformed CSV row validation", "missing score for row 'harry potter,harry-potter-content-id,\n'", ["harry potter", "harry-potter-content-id", nil]
    end

    context "content id is missing" do
      it_behaves_like "a malformed CSV row validation", "missing content id for row 'harry potter,,3\n'", ["harry potter", nil, 3]
    end

    context "when a valid csv is provided" do
      before do
        csv_data = mock_clickstream_csv
        datafile = build_datafile("mock_clickstream_csv", csv_data)
        @datafile = datafile
      end

      let(:expected_output) do
        {
          "harry potter" => [{ score: 3, link: "harry-potter-content-id" }],
          "passport" => [{ score: 3, link: "passport-content-id" }],
        }
      end

      it "creates a hash of csv data" do
        hash = evaluator.load_from_csv(@datafile)
        expect(hash).to eq(expected_output)
      end
    end
  end
end
