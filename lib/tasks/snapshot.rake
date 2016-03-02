require "snapshot/snapshot_repository"
require "snapshot/bucket"
require "rest-client"
require "aws-sdk"
require "date"
require "time"

# Generate a snapshot name based on the current time
def generate_name(indices)
  "#{indices.join('-')}-#{Time.now.utc.iso8601}-#{SecureRandom.uuid}".downcase
end

namespace :rummager do
  namespace :snapshot do
    desc "Start a snapshot of the public elasticsearch indices."
    task :run, [:snapshot_name, :repository_name] do |_, args|
      repository_name = args.repository_name || search_config.repository_name

      indices = index_names
      snapshot_name = args.snapshot_name || generate_name(indices)

      Rake::Task["rummager:snapshot:create_repository"].invoke(repository_name)

      repo = Snapshot::SnapshotRepository.new(
        base_uri: elasticsearch_uri,
        repository_name: repository_name,
      )

      puts snapshot_name
      puts repo.create_snapshot(snapshot_name, indices)
    end

    desc "Get the status of a snapshot, e.g. SUCCESS"
    task :check, [:repository_name, :snapshot_name] do |_, args|
      raise "A 'snapshot_name' must be supplied" unless args.snapshot_name
      repository_name = args.repository_name || search_config.repository_name

      begin
        repo = Snapshot::SnapshotRepository.new(
          base_uri: elasticsearch_uri,
          repository_name: repository_name,
        )
        puts repo.check_snapshot(args.snapshot_name)
      rescue RestClient::ResourceNotFound
        puts "Missing repository or snapshot. Try rummager:snapshot:list"
      end
    end

    desc "Create or update a snapshot repository backed by S3"
    task :create_repository, [:repository_name] do |_, args|
      repository_name = args.repository_name || search_config.repository_name

      validate_env(%w(
        AWS_BUCKET_NAME
        AWS_ACCESS_KEY_ID
        AWS_BUCKET_REGION
        AWS_SECRET_ACCESS_KEY
      ))

      client = Snapshot::SnapshotRepository.new(
        base_uri: elasticsearch_uri,
        repository_name: repository_name,
      )
      settings = {
         region: ENV["AWS_BUCKET_REGION"],
         bucket: ENV["AWS_BUCKET_NAME"],
         access_key: ENV["AWS_ACCESS_KEY_ID"],
         secret_key: ENV["AWS_SECRET_ACCESS_KEY"],
         base_path: repository_name,
      }
      acknowledged = client.create_repository("s3", settings)["acknowledged"]

      raise "Snapshot not acknowledged" unless acknowledged
    end

    desc "List all snapshots in the repository"
    task :list, [:repository_name] do |_, args|
      repository_name = args.repository_name || search_config.repository_name

      puts bucket.list_snapshots(repository_name, before_time: Time.now)
    end

    desc "Get latest snapshot.
    You can optionally pass a datetime parameter to filter out any snapshots
    created afterwards.

    If you don't pass it, it will default to the time in which the rake task is run.

    This is used to monitor the ongoing snapshot process and make sure our
    repository is keeping up to date.
    "
    task :latest, [:before_time, :repository_name] do |_, args|
      repository_name = args.repository_name || search_config.repository_name

      if args.before_time
        before_time = DateTime.parse(before_time).to_time
      else
        before_time = Time.now
      end

      snapshots = bucket.list_snapshots(repository_name, before_time: before_time)

      snapshot_repository = Snapshot::SnapshotRepository.new(
        base_uri: elasticsearch_uri,
        repository_name: repository_name,
      )

      puts snapshot_repository.last_successful_snapshot(snapshots) || "No snapshots present."
    end

    desc "Start restoring a snapshot and print the new index names"
    task :restore, [:snapshot_name, :repository_name] do |_, args|
      raise "A 'snapshot_name' must be supplied" unless args.snapshot_name
      repository_name = args.repository_name || search_config.repository_name

      snapshot_repository = Snapshot::SnapshotRepository.new(
        base_uri: elasticsearch_uri,
        repository_name: repository_name,
      )
      puts "Restored to indices:"
      puts snapshot_repository.restore_indexes(args.snapshot_name, index_names)
    end
  end

  def bucket
    validate_env(%w(AWS_BUCKET_NAME AWS_BUCKET_REGION))

    Snapshot::Bucket.new(
      bucket_name: ENV["AWS_BUCKET_NAME"],
      client: Aws::S3::Client.new(region: ENV["AWS_BUCKET_REGION"])
    )
  end

  def validate_env(required_names)
    unless required_names.all? { |name| ENV[name] }
      raise "#{required_names.join(", ")} must be set as environment variables"
    end
  end
end
