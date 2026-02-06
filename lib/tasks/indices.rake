require "rummager"
require_relative "./task_helper"

namespace :search do
  desc "Lists current indices, pass [all] to show inactive indices"
  task :list_indices, :all, :clusters do |_, args|
    show_all = args[:all] || false
    clusters_from_args(args).each do |cluster|
      puts "CLUSTER #{cluster.key}"
      puts "===================================================="
      index_names.each do |name|
        index_group = search_server(cluster:).index_group(name)
        active_index_name = index_group.current.real_name
        index_names = if show_all
                        index_group.index_names
                      else
                        [active_index_name]
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
        search_server(cluster:).index(index_name).lock
      end
    end
  end

  desc "Unlock the index for writes"
  task :unlock, :clusters do |_, args|
    clusters_from_args(args).each do |cluster|
      index_names.each do |index_name|
        search_server(cluster:).index(index_name).unlock
      end
    end
  end

  desc "Update popularity data in indices.

Update all data in the index inplace (without locks) with the new popularity
data using sidekiq jobs.

This does not update the schema.
"
  task :update_popularity do
    index_names.each do |index_name|
      GovukIndex::PopularityUpdater.update(index_name, process_all: ENV.key?("PROCESS_ALL_DATA"))
    end
  end

  desc "Update supertypes from govuk_document_types gem.

Update all data in the index inplace (without locks) with supertypes from the
govuk_document_types gem using sidekiq jobs.

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
        migrator = SchemaMigrator.new(index_name, cluster:)
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

  desc "Update the schema in place to reflect the current Search API configuration. This task is idempotent.

If there are changes to configuration that cannot be made to the live schema because the change is not applicable to
the existing data, you will need to run the \"migrate_schema\" task instead, which requires locking the index."
  task :update_schema, [:clusters] do |_, args|
    clusters_from_args(args).each do |cluster|
      puts "Updating schema on cluster #{cluster.key}"

      index_names.each do |index_name|
        index_group = SearchConfig.instance(cluster).search_server.index_group(index_name)
        synchroniser = SchemaSynchroniser.new(index_group)
        synchroniser.call
        synchroniser.synchronised_types.each do |type|
          puts "Successfully synchronised #{type} type on #{index_name} index"
        end
        synchroniser.errors.each do |type, exception|
          puts "Unable to synchronise #{type} on #{index_name} due to #{exception.message}"
        end
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
        next unless new_index_name.include?(index_name)

        puts "Switching #{index_name} -> #{args.new_index_name}"
        index_group = search_server(cluster:).index_group(index_name)
        index_group.switch_to(index_group.index_for_name(new_index_name))
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
        search_server(cluster:).index_group(index_name).clean
      end
    end
  end

  desc "Cleans out unused indices older than the number of days given by the MAX_INDEX_AGE flag"
  task :timed_clean do
    Clusters.active.each do |cluster|
      index_names.each do |index_name|
        search_server(cluster:).index_group(index_name).timed_clean(max_index_age)
      end
    end
  end

  desc "Check whether a restored index has recovered"
  task :check_recovery, [:index_name, :clusters] do |_, args|
    raise "An 'index_name' must be supplied" unless args.index_name

    clusters_from_args(args).each do |cluster|
      index = search_server(cluster:).index_group(args.index_name).current
      puts "Recovery status of #{args.index_name} on cluster #{cluster.key} (#{cluster.uri}):"
      puts index.index_recovered?
    end
  end
end
