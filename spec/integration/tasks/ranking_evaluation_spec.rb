require "rake"
require_relative "../../support/rank_eval_test_helpers"

RSpec.describe "ranking_evaluation" do
  include RankEvalTestHelpers

  before { Rake::Task[task_name].reenable }

  describe "ranking_evaluation" do
    let(:task_name) { "ranking_evaluation" }

    context "the bucket is provided and contains a judgement csv" do
      let(:bucket) { "test-bucket" }
      let(:filename) { "judgements.csv" }

      before do
        allow(Services).to receive(:s3_client).and_return(FakeS3.fake_s3_client)
        Services.s3_client.put_object(key: filename,
                                      bucket:,
                                      body: mock_clickstream_csv)

        stub_rank_eval_request
      end

      it "calculates how well search performs" do
        ClimateControl.modify AWS_S3_RELEVANCY_BUCKET_NAME: bucket do
          output = capture_stdout { Rake::Task[task_name].invoke }
          expect(output).to include("Ignoring 1 judgements for passport-content-id queried with query 'passport'")
          expect(output.squeeze(" ")).to include(rank_eval_expected_output)
        end
      end
    end

    context "no bucket or datafile is provided" do
      it "raises an error" do
        expect { Rake::Task[task_name].invoke }
          .to raise_error("Missing required AWS_S3_RELEVANCY_BUCKET_NAME envvar")
      end
    end
  end
end
