module FakeS3
  LAST_MODIFIED = Time.utc(2025, 12, 13, 17, 30, 0).freeze

  def self.fake_s3_client
    fake_s3 = {}
    Aws::S3::Client.new(stub_responses: true).tap do |client|
      client.stub_responses(
        :put_object, lambda { |context|
                       bucket = context.params[:bucket]
                       key = context.params[:key]
                       body = context.params[:body]
                       fake_s3[bucket] ||= {}
                       fake_s3[bucket][key] = {
                         body: body,
                         last_modified: LAST_MODIFIED,
                       }
                       {}
                     }
      )
      client.stub_responses(
        :get_object, lambda { |context|
                       bucket = context.params[:bucket]
                       key = context.params[:key]
                       object = fake_s3.dig(bucket, key)

                       object.nil? ? "NoSuchKey" : object
                     }
      )
    end
  end
end
