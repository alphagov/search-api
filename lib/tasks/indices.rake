require "rummager"

namespace :search do
  desc "Lists current indices, pass [all] to show inactive indices"
  task :list_indices, :all, :clusters do |_, args|
    show_all = args[:all] || false
    clusters_from_args(args).each do |cluster|
      puts "CLUSTER #{cluster.key}"
      puts "===================================================="
      index_names.each do |name|
        index_group = search_server(cluster: cluster).index_group(name)
        active_index_name = index_group.current.real_name
        if show_all
          index_names = index_group.index_names
        else
          index_names = [active_index_name]
        end
        puts "#{name}:"
        index_names.sort.each do |index_name|
          if index_name == active_index_name
            puts "* #{index_name}"
          else
            puts "  #{index_name}"
          end
        end
        puts
      end
    end
  end

  desc "Create a brand new indices and assign an alias if no alias currently exists
        Specify clusters to run this against; by default runs against all clusters.
  "
  task :create_all_indices, :clusters do |_, args|
    clusters_from_args(args).each do |cluster|
      index_names.each do |index_name|
        index_group = SearchConfig.instance(cluster).search_server.index_group(index_name)
        index = index_group.create_index
        index_group.switch_to(index) unless index_group.current_real
      end
    end
  end

  desc "Create a brand new index and assign an alias if no alias currently exists"
  task :create_index, :index_name, :clusters do |_, args|
    clusters_from_args(args).each do |cluster|
      index_group = SearchConfig.instance(cluster).search_server.index_group(args[:index_name])
      index = index_group.create_index
      index_group.switch_to(index) unless index_group.current_real
    end
  end

  desc "Lock the index for writes"
  task :lock, :clusters do |_, args|
    clusters_from_args(args).each do |cluster|
      index_names.each do |index_name|
        search_server(cluster: cluster).index(index_name).lock
      end
    end
  end

  desc "Unlock the index for writes"
  task :unlock, :clusters do |_, args|
    clusters_from_args(args).each do |cluster|
      index_names.each do |index_name|
        search_server(cluster: cluster).index(index_name).unlock
      end
    end
  end

  desc "Sync unmigrated data into govuk

While we are migrating data to govuk, it is important that govuk has
all the data from specified index in order for soring to be calculated
correctly
"
  task :sync_govuk do
    raise("Can not migrate multiple indices") if index_names.count > 1
    raise("Can not migrate for govuk index") if index_names.include?("govuk")

    GovukIndex::SyncUpdater.update(source_index: index_names.first)
  end

  desc "Update popularity data in indices.

Update all data in the index inplace (without locks) with the new popularity
data using sidekiq workers.

This does not update the schema.
"
  task :update_popularity do
    index_names.each do |index_name|
      GovukIndex::PopularityUpdater.update(index_name, process_all: ENV.key?("PROCESS_ALL_DATA"))
    end
  end

  desc "Update supertypes from govuk_document_types gem.

Update all data in the index inplace (without locks) with supertypes from the
govuk_document_types gem using sidekiq workers.

This does not update the schema.
"
  task :update_supertypes do
    index_names.each do |index_name|
      GovukIndex::SupertypeUpdater.update(index_name)
    end
  end

  desc "Migrate the data to a new schema definition

Lock the current index, migrate all the data to a new index,
wait for the process to complete, switch to the new index and
release the lock.

You should run this task if the index schema has changed.

Specify a list of clusters `migrate_schema['A B C']` if you like, otherwise
this task will run against all active clusters.
"
  task :migrate_schema, [:clusters] do |_, args|
    clusters_from_args(args).each do |cluster|
      puts "Migrating schema on cluster #{cluster.key}"
      failed_indices = []

      index_names.each do |index_name|
        migrator = SchemaMigrator.new(index_name, cluster: cluster)
        migrator.reindex

        if migrator.failed == true
          failed_indices << index_name
        else
          # We need to switch the aliases without a lock, since
          # read_only_allow_delete prevents aliases being changed
          # After running the schema migration, traffic must be
          # represented anyway, so the race condition is irrelevant
          migrator.switch_to_new_index
        end
      end

      raise "Failure during reindexing for: #{failed_indices.join(', ')}" if failed_indices.any?
    end
  end

  desc "Switches an index group to a new index WITHOUT transferring the data"
  task :switch_to_empty_index, :clusters do |_, args|
    # Note that this task will effectively clear out the index, so shouldn't be
    # run on production without some serious consideration.
    clusters_from_args(args).each do |cluster|
      index_names.each do |index_name|
        index_group = search_server(cluster: cluster).index_group(index_name)
        index_group.switch_to index_group.create_index
      end
    end
  end

  desc "Switches an index group to a specific index WITHOUT transferring data"
  task :switch_to_named_index, [:new_index_name, :clusters] do |_, args|
    # This makes no assumptions on the contents of the new index.
    # If it has been restored from a snapshot, you should check that the
    # index is fully recovered first. See :check_recovery.
    raise "The new index name must be supplied" unless args.new_index_name

    new_index_name = args.new_index_name

    clusters_from_args(args).each do |cluster|
      index_names.each do |index_name|
        if new_index_name.include?(index_name)
          puts "Switching #{index_name} -> #{args.new_index_name}"
          index_group = search_server(cluster: cluster).index_group(index_name)
          index_group.switch_to(index_group.index_for_name(new_index_name))
        end
      end
    end
  end

  desc "Cleans out old indices"
  task :clean do
    # as we only want to clean the indices for the versions that matches from the overnight copy task
    # if we didn't check this we could potentially attempt to delete one of the new indices as we are importing
    # data into it.
    Clusters.active.each do |cluster|
      index_names.each do |index_name|
        search_server(cluster: cluster).index_group(index_name).clean
      end
    end
  end

  desc "Cleans out unused indices older than the number of days given by the MAX_INDEX_AGE flag"
  task :timed_clean do
    Clusters.active.each do |cluster|
      index_names.each do |index_name|
        search_server(cluster: cluster).index_group(index_name).timed_clean(max_index_age)
      end
    end
  end

  desc "Check whether a restored index has recovered"
  task :check_recovery, [:index_name, :clusters] do |_, args|
    raise "An 'index_name' must be supplied" unless args.index_name

    clusters_from_args(args).each do |cluster|
      puts "Recovery status of #{args.index_name} on cluster #{cluster.key} (#{cluster.uri}):"
      puts SearchIndices::Index.index_recovered?(
        base_uri: cluster.uri,
        index_name: args.index_name,
      )
    end
  end

  desc "Monitor the search indices and send data to statsd"
  task :monitor_indices do
    Clusters.active.each do |cluster|
      client = Services.elasticsearch(cluster: cluster)
      statsd = Services.statsd_client
      missing = []
      cluster_name = "cluster_#{cluster.key}"

      SearchConfig.all_index_names.each do |index|
        stats = client.indices.stats index: index, docs: true
        docs = stats["_all"]["primaries"]["docs"]

        count = docs["count"]
        statsd.gauge("#{cluster_name}.#{index}_index.docs.total", count)
        puts "#{cluster_name}.#{index}_index.docs.total=#{count}"

        deleted = docs["deleted"]
        statsd.gauge("#{cluster_name}.#{index}_index.docs.deleted", deleted)
        puts "#{cluster_name}.#{index}_index.docs.deleted=#{deleted}"
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        missing << index
      end

      raise Exception, "Missing index (on cluster #{cluster_name}) #{missing}!" unless missing.empty?
    end
  end

  desc "
  Check for any taxons that are not in a draft state for a particular format.
  Usage
  rake 'search:check_for_non_draft_taxons[format_name, elasticsearch_index]'
  "
  task :check_for_non_draft_taxons, [:format, :index_name] do |_, args|
    warn_for_single_cluster_run
    format = args[:format]
    index  = args[:index_name]

    if format.nil?
      puts "Specify format"
    elsif index.nil?
      puts "Specify an index"
    else
      client = Services.elasticsearch(hosts: Clusters.default_cluster, timeout: 5.0)
      publishing_api = Services.publishing_api

      taxons = {}
      ScrollEnumerator.new(
        client: client,
        search_body: { query: { term: { format: format } } },
        batch_size: 500,
        index_names: index,
      ) { |hit| hit }.map do |hit|
        taxons[hit["_id"]] = hit["_source"]["taxons"]
      end

      ids_to_check = []
      taxons.each do |id, content_ids|
        ids_to_check << id if content_ids.any? do |content_id|
          content_item = publishing_api.get_content(content_id).to_hash
          content_item["publication_state"] != "draft"
        end
      end

      if ids_to_check.empty?
        puts "All taxons in draft state"
      else
        puts ids_to_check
      end
    end
  end
end
