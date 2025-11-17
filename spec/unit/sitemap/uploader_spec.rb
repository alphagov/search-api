require "spec_helper"

RSpec.describe Sitemap::Uploader do
  let(:bucket_name) { "test-bucket" }
  let(:file_name) { "sitemap.xml" }
  let(:file_content) { "<sitemap>...</sitemap>" }
  let(:s3_object_double) { instance_double(Aws::S3::Object) }
  let(:logger) { Logging.logger[described_class] }

  subject(:uploader) { described_class.new(bucket_name) }

  before do
    allow(Aws::S3::Object)
      .to receive(:new)
      .with(bucket_name:, key: file_name)
      .and_return(s3_object_double)
  end

  context "when the file uploads successfully" do
    let(:put_object_output) { instance_double(Aws::S3::Types::PutObjectOutput) }

    before do
      allow(s3_object_double)
        .to receive(:put)
        .with(body: file_content)
        .and_return(put_object_output)
    end

    it "uploads a sitemap to an AWS S3 bucket" do
      expect(logger)
        .to receive(:info)
        .with("Uploading #{file_name} ...")

      expect(Aws::S3::Object)
        .to receive(:new)
        .with(bucket_name:, key: file_name)

      expect(s3_object_double)
        .to receive(:put)
        .with(body: file_content)

      uploader.upload(file_content:, file_name:)
    end
  end

  context "when then file fails to upload" do
    before do
      allow(s3_object_double)
        .to receive(:put)
        .with(body: file_content)
        .and_return(nil)
    end

    it "raises an error" do
      expected_error = "Failed to create sitemap file '#{file_name}'"

      expect { uploader.upload(file_content:, file_name:).to raise_error(expected_error) }
    end
  end
end
