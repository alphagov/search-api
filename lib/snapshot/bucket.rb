module Snapshot
  class Bucket
    def initialize(bucket_name:, client:)
      @aws_client = client
      @bucket_name = bucket_name
    end

    def repository_prefix(repository_name)
      "#{repository_name}/metadata-"
    end

    # List names of all available snapshots, ignoring status.
    # This information is not always visible in the elasticsearch API,
    # so we go directly to the backing store (S3)
    # Ordered by modification date ascending.
    def list_snapshots(repository_name, before_time:)
      prefix = repository_prefix(repository_name)

      all_snapshots = @aws_client.list_objects({
          bucket: @bucket_name,
          prefix: prefix
      }).contents

      all_snapshots.select! { |snapshot| snapshot.last_modified <= before_time }

      all_snapshots.sort_by!(&:last_modified)

      all_snapshots.map do |snapshot|
        snapshot.key.sub(prefix, "")
      end
    end
  end
end
