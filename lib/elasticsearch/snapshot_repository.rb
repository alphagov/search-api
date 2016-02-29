require "elasticsearch/client"
require 'pry'
require "logging"
require "json"

module Elasticsearch
  class SnapshotRepositoryBusy < Exception
  end

  class SnapshotRepository
    def initialize(base_uri:, repository_name:)
      @client = Client.new(url_for(base_uri, repository_name))
      @repository_name = repository_name
    end

    # Create a snapshot repository
    # The verify param requires delete permissions on the underlying data store
    def create_repository(type, settings)
      response = @client.put(
        "?verify=false",
        {
          "type" => type,
          "settings" => settings
        }.to_json
      )
      JSON(response)
    end

    # Start a snapshot of one or more indices.
    # snapshot_name is assumed to be unique.
    def snapshot(snapshot_name, index_names)
      begin
        response = @client.put(
          snapshot_name,
          {
            "indices" => index_names.join(","),
            "include_global_state" => false
          }.to_json
        )
      rescue RestClient::ServiceUnavailable
        # API goes unresponsive when a snapshot is in progress.
        raise SnapshotRepositoryBusy
      end

      JSON(response)
    end

    # Get the status of a previously started snapshot
    def check_snapshot(snapshot_name)
      response = JSON(
        @client.get("#{snapshot_name}/_status")
      )
      snapshot = response["snapshots"].first

      logger.info(
        "Snapshot #{snapshot['snapshot']}: #{snapshot['state']}"
      )
      logger.debug(snapshot["shards_stats"].to_s)

      snapshot["state"]
    end

    def in_progress_snapshots
      snapshots = JSON(@client.get("_status"))["snapshots"]
      snapshots.reject! { |snapshot| snapshot.fetch("state") == "SUCCESS" }
      snapshots.map { |snapshot| snapshot.fetch("snapshot") }
    end

    def last_successful_snapshot(snapshots)
      (snapshots - in_progress_snapshots).last
    end

    def restore_indexes(snapshot_name, index_groups)
      # Restore the requested indexes from a snapshot.
      # The snapshot contains indexes with their "real" names, e.g.:
      # mainstream-2016-02-25t17:14:51z-7f3aa400-76a0-4247-ba8a-1a1f3cac513c
      #
      # We restore them to new indices, which we can point the aliases to
      # once the recovery has completed.
      # The new names contain the current timestamp and a "restored" prefix.
      indices = JSON(@client.get(snapshot_name))["snapshots"].first["indices"]
      indices = self.class.select_indices_from_groups(indices, index_groups)

      uuid = SecureRandom.uuid
      restore_time = Time.now.utc.iso8601
      rename_pattern = '(.+)-\d{4}-\d{2}-\d{2}t\d{2}:\d{2}:\d{2}z-[0-9a-f][-0-9a-f]*\Z'
      rename_replacement = "restored-$1-#{restore_time}-#{uuid}".downcase

      begin
        @client.post("#{snapshot_name}/_restore", {
          "indices" => indices.values.join(","),
          "rename_pattern" => rename_pattern,
          "rename_replacement" => rename_replacement
        }.to_json)
      rescue RestClient::ServiceUnavailable
        # API goes unresponsive when a restore is in progress.
        raise SnapshotRepositoryBusy
      end

      # Work out the index names elasticsearch will create for us, because the
      # request doesn't return them.
      indices.values.map do |index|
        index.gsub(Regexp.new(rename_pattern)) do
          "restored-#{$1}-#{restore_time}-#{uuid}".downcase
        end
      end
    end

    # Create a hash from group names to "real" index names
    def self.select_indices_from_groups(indices, index_groups)
      indices.each_with_object({}) do |index, indices_for_groups|
        index_groups.each do |index_group|
          if index.start_with?(index_group)
            indices_for_groups[index_group] = index
          end
        end
      end
    end

  private

    def logger
      Logging.logger[self]
    end

    def url_for(base_uri, repository_name)
      "#{base_uri}/_snapshot/#{CGI.escape(repository_name)}/"
    end
  end
end
