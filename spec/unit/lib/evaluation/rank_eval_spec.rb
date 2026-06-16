require "spec_helper"
require "tempfile"
require_relative "../../../support/rank_eval_test_helpers"
require_relative "../../../../lib/evaluation/rank_eval"

RSpec.describe Evaluation::RankEval do
  include RankEvalTestHelpers

  let(:evaluator) { described_class.new }

  RSpec.shared_examples "a malformed CSV row validation" do |expected_error, bad_row|
    around do |example|
      csv_data = create_csv(bad_row)
      datafile = build_datafile("malformed_csv", csv_data)
      @datafile = datafile

      example.run

      delete_datafile(datafile)
    end

    it "raises the expected validation error" do
      expect { evaluator.load_from_csv(@datafile) }.to raise_error(expected_error)
    end
  end

  RSpec.shared_examples "Raises the Publishing API error" do |error_class|
    before do
      publishing_api_stub
      csv_data = mock_clickstream_csv
      datafile = build_datafile("mock_clickstream_csv", csv_data)
      @datafile = datafile
    end

    it "raises the error" do
      expect { evaluator.load_from_csv(@datafile) }.to raise_error(error_class)
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

    context "when publishing api has the content" do
      before do
        stub_publishing_api_has_item({ content_id: "harry-potter-content-id", base_path: "/harry-potter", document_type: "guide" })
        stub_publishing_api_has_item({ content_id: "passport-content-id", base_path: "/passport", document_type: "guide" })
      end

      let(:expected_output) do
        {
          "harry potter" => [{ score: 3, link: "/harry-potter" }],
          "passport" => [{ score: 3, link: "/passport" }],
        }
      end

      let(:datafile) { build_datafile("mock_clickstream_csv", mock_clickstream_csv) }

      it "sends content id to publishing api to fetch the relevant document" do
        @datafile = datafile
        evaluator.load_from_csv(@datafile)
        delete_datafile(@datafile)

        # https://github.com/alphagov/gds-api-adapters/blob/017768c7a4637334321855a51c47b8a36385ae42/lib/gds_api/test_helpers/publishing_api.rb#L310
        assert_publishing_api(:get, "#{Plek.find('publishing-api')}/v2/content/harry-potter-content-id")
        assert_publishing_api(:get, "#{Plek.find('publishing-api')}/v2/content/passport-content-id", nil, 2)
      end

      it "creates a hash of csv data" do
        @datafile = datafile
        hash = evaluator.load_from_csv(@datafile)
        delete_datafile(@datafile)

        expect(hash).to eq(expected_output)
      end

      context "when the csv contains external content links" do
        before do
          stub_publishing_api_has_item({ content_id: "external-content-content-id", document_type: "external_content" })
        end

        let(:csv_data) { create_csv(%w[contact external-content-content-id 3]) }
        let(:datafile) { build_datafile("external_content_csv", csv_data) }
        let(:expected_output) { { "contact" => [{ score: 3, link: "external-content-content-id" }] } }

        it "it uses content id as the link" do
          @datafile = datafile
          hash = evaluator.load_from_csv(@datafile)
          delete_datafile(@datafile)

          assert_publishing_api(:get, "#{Plek.find('publishing-api')}/v2/content/external-content-content-id")

          expect(hash).to eq(expected_output)
        end
      end
    end

    context "when the publishing api is unavailable" do
      let(:publishing_api_stub) { stub_publishing_api_isnt_available }

      it_behaves_like "Raises the Publishing API error", GdsApi::HTTPUnavailable
    end

    context "when the content item is not found" do
      let(:publishing_api_stub) { stub_any_publishing_api_call_to_return_not_found }

      it_behaves_like "Raises the Publishing API error", GdsApi::HTTPNotFound
    end

    context "when publishing API timesout" do
      let(:publishing_api_stub) { stub_any_publishing_api_call_to_return_timeout }

      it_behaves_like "Raises the Publishing API error", GdsApi::TimedOutException
    end
  end
end
