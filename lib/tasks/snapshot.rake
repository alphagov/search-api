require "elasticsearch/snapshot_repository"
require "elasticsearch/bucket"
require "rest-client"
require "pry-byebug"
require "aws-sdk"
require "date"

namespace :rummager do
  namespace :snapshot do

    desc "Start a snapshot of the public elasticsearch indices."
    task :run, [:repository_name, :snapshot_name] do |_, args|

      repository_name = args.repository_name or raise "A 'repository_name' must be supplied"
      snapshot_name = args.snapshot_name or raise "A 'snapshot_name' must be supplied"

      repo = Elasticsearch::SnapshotRepository.new(
        base_uri: elasticsearch_uri,
        repository_name: repository_name,
      )

      puts repo.snapshot(snapshot_name, index_names)
    end

    desc "Get the status of a snapshot, e.g. SUCCESS"
    task :check, [:repository_name, :snapshot_name] do |_, args|
      repository_name = args.repository_name or raise "A 'repository_name' must be supplied"
      snapshot_name = args.snapshot_name or raise "A 'snapshot_name' must be supplied"

      begin
        repo = Elasticsearch::SnapshotRepository.new(
          base_uri: elasticsearch_uri,
          repository_name: repository_name,
        )
        puts repo.check_snapshot(snapshot_name)
      rescue RestClient::ResourceNotFound
        puts "Missing repository or snapshot. Try rummager:snapshot:list[#{repository_name}]"
      end
    end

    desc "Create or update a snapshot repository backed by S3"
    task :create_repository, [:repository_name] do |_, args|

      repository_name = args.repository_name or raise "A 'repository_name' must be supplied"

      client = Elasticsearch::SnapshotRepository.new(
        base_uri: elasticsearch_uri,
        repository_name: repository_name,
      )
      settings = {
         region: "eu-west-1",
         bucket: search_config.snapshot_bucket_name,
         access_key: ENV["AWS_ACCESS_KEY_ID"],
         secret_key: ENV["AWS_SECRET_ACCESS_KEY"],
         base_path: repository_name,
      }
      puts client.create_repository("s3", settings)
    end

    desc "List all snapshots in the repository"
    task :list, [:repository_name] do |_, args|

      repository_name = args.repository_name or raise "A 'repository_name' must be supplied"

      puts bucket.list_snapshots(args[:repository_name], before_time: Time.now)
    end

    desc "Get latest snapshot.
    You can optionally pass a datetime parameter to filter out any snapshots
    created afterwards.

    If you don't pass it, it will default to the time in which the rake task is run.

    This is used to monitor the ongoing snapshot process and make sure our
    repository is keeping up to date.
    "
    task :latest, [:repository_name, :before_time] do |_, args|

      repository_name = args.repository_name or raise "A 'repository_name' must be supplied"

      if args.before_time
        before_time = DateTime.parse(before_time).to_time
      else
        before_time = Time.now
      end

      snapshots = bucket.list_snapshots(repository_name, before_time: before_time)

      snapshot_repository = Elasticsearch::SnapshotRepository.new(
        base_uri: elasticsearch_uri,
        repository_name: repository_name,
      )

      puts snapshot_repository.last_successful_snapshot(snapshots) || "No snapshots present."
    end

    desc "Start restoring a snapshot and print the new index names"
    task :restore, [:repository_name, :snapshot_name] do |_, args|

      repository_name = args.repository_name or raise "A 'repository_name' must be supplied"
      snapshot_name   = args.snapshot_name or raise "A 'snapshot_name' must be supplied"

      snapshot_repository = Elasticsearch::SnapshotRepository.new(
        base_uri: elasticsearch_uri,
        repository_name: repository_name,
      )
      puts snapshot_repository.restore_indexes(snapshot_name, index_names)
    end
  end
end
