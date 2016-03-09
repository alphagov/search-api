require 'elasticsearch'
require "logging"
require "json"

module Snapshot
  class SnapshotRepository
    attr_reader :repository_name

    def initialize(base_uri:, repository_name:, **client_opts)
      @client = Elasticsearch::Client.new(host: base_uri, **client_opts).snapshot
      @repository_name = repository_name
    end

    # Create a snapshot repository
    # The verify param requires delete permissions on the underlying data store
    def create_repository(type, settings)
      client.create_repository(
        repository: "#{repository_name}",
        body: {
          type: type,
          settings: settings
        }
      )
    end

    # Start a snapshot of one or more indices.
    # snapshot_name is assumed to be unique.
    #
    # Raises a ServiceUnavailable exception if elasticsearch is already taking
    # another snapshot.
    def create_snapshot(snapshot_name, index_names)
      client.create(
        repository: repository_name,
        snapshot: snapshot_name,
        body: {
          indices: index_names.join(","),
          include_global_state: false
        }
      )
    end

    # Get the status of a previously started snapshot
    def check_snapshot(snapshot_name)
      response = client.status(
        repository: repository_name,
        snapshot: snapshot_name,
      )
      snapshot = response["snapshots"].first

      logger.info(
        "Snapshot #{snapshot['snapshot']}: #{snapshot['state']}"
      )
      logger.debug(snapshot["shards_stats"].to_s)

      snapshot["state"]
    end

    def delete_snapshot(snapshot_name)
      client.delete(repository: repository_name, snapshot: snapshot_name)
    end

    def in_progress_snapshots
      client.status(repository: repository_name)["snapshots"]
        .reject { |snapshot| snapshot.fetch("state") == "SUCCESS" }
        .map { |snapshot| snapshot.fetch("snapshot") }
    end

    def last_successful_snapshot(snapshots)
      (snapshots - in_progress_snapshots).last
    end

    # Restore the indexes matching the specified group names
    # The snapshot contains indexes with their "real" names, e.g.:
    # mainstream-2016-02-25t17:14:51z-7f3aa400-76a0-4247-ba8a-1a1f3cac513c
    def restore_indexes(snapshot_name, index_groups)
      response = client.get(
        repository: repository_name,
        snapshot: snapshot_name
      )
      all_indices = response["snapshots"].first["indices"]
      selected_indices = select_indices_from_groups(all_indices, index_groups)

      Restorer.new(
        client: client,
        repository_name: repository_name,
        snapshot_name: snapshot_name,
        snapshot_indices: selected_indices
      ).run
    end

  private

    attr_reader :client

    def logger
      Logging.logger[self]
    end

    # Select only the indices matching one of our requested groups
    def select_indices_from_groups(indices, index_groups)
      indices.select do |index|
        index_groups.any? do |index_group|
          index.include?(index_group)
        end
      end
    end
  end

  class Restorer
    RENAME_PATTERN = '(restored-)*(.+)-\d{4}-\d{2}-\d{2}t\d{2}:\d{2}:\d{2}z-[0-9a-f][-0-9a-f]*\Z'

    def initialize(client:, repository_name:, snapshot_name:, snapshot_indices:)
      @client = client
      @snapshot_name = snapshot_name
      @snapshot_indices = snapshot_indices
      @uuid = SecureRandom.uuid
      @restore_time = Time.now.utc.iso8601
      @repository_name = repository_name
    end

    # Restore to new indices, which we can point the aliases to once the
    # recovery has completed.
    # The new names contain the current timestamp and a "restored" prefix.

    # Raises a ServiceUnavailable exception if elasticsearch is already
    # restoring another snapshot.
    def run
      client.restore(
        repository: repository_name,
        snapshot: snapshot_name,
        body: {
          indices: snapshot_indices.join(","),
          rename_pattern: RENAME_PATTERN,
          rename_replacement: "#{prefix}$2#{suffix}".downcase
        }
      )

      restored_index_names
    end

    # Work out the index names elasticsearch will create for us.
    # This is not returned by the request itself.
    def restored_index_names
      snapshot_indices.map do |index|
        index.gsub(Regexp.new(RENAME_PATTERN)) do
          "#{prefix}#{$2}#{suffix}".downcase
        end
      end
    end

  private

    attr_reader :client, :repository_name, :snapshot_name, :snapshot_indices

    def prefix
      "restored-"
    end

    def suffix
      "-#{@restore_time}-#{@uuid}"
    end
  end
end
