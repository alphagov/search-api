require "test_helper"
require "snapshot/bucket"
require "aws-sdk"
require 'time'

class BucketTest < MiniTest::Unit::TestCase
  def setup
    @client = Minitest::Mock.new
    @response = Minitest::Mock.new
    @response.expect(:contents, [
      Aws::S3::Types::Object.new(key: "my-repository/metadata-snap2000", last_modified: Time.new(2000)),
      Aws::S3::Types::Object.new(key: "my-repository/metadata-snap2003", last_modified: Time.new(2003)),
      Aws::S3::Types::Object.new(key: "my-repository/metadata-snap2001", last_modified: Time.new(2001)),
    ])
    @client.expect(:list_objects, @response, [{ bucket: "bucket", prefix: "my-repository/metadata-" }])
  end

  def test_returns_snapshots_ordered_by_date
    bucket = Snapshot::Bucket.new(bucket_name: "bucket", client: @client)
    names = bucket.list_snapshots("my-repository", before_time: Time.now)

    assert_equal(names, %w(snap2000 snap2001 snap2003))
  end

  def test_returns_snapshots_filtered_by_date
    bucket = Snapshot::Bucket.new(bucket_name: "bucket", client: @client)
    names = bucket.list_snapshots("my-repository", before_time: Time.new(2001))

    assert_equal(names, %w(snap2000 snap2001))
  end
end
