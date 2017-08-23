require 'rummager'

namespace :rummager do
  # this is needed to support the migration to ES 2.4
  ELASTICSEARCH_VERSION = '1.7'.freeze

  desc "Lists current Rummager indices, pass [all] to show inactive indices"
  task :list_indices, :all do |_, args|
    show_all = args[:all] || false
    index_names.each do |name|
      index_group = search_server.index_group(name)
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

  desc "Create a brand new index and assign an alias if no alias currently exists"
  task :create_index, :index_name do |_, args|
    index_group = search_config.search_server.index_group(args[:index_name])
    index = index_group.create_index
    index_group.switch_to(index) unless index_group.current_real
  end

  desc "Update popularity data in indices.

Update all data in the index inplace (without locks) with the new popularity
data using sidekiq workers.

This does not update the schema.
"
  task :update_popularity do
    index_names.each do |index_name|
      GovukIndex::PopularityUpdater.update(index_name)
    end
  end

  desc "(deprecated) Migrate the data to a new schema definition

Lock the current index, migrate all the data to a new index,
wait for the process to complete, switch to the new index and
release the lock.

You should run this task if the index schema has changed.
"
  task :migrate_schema do
    raise('Please set `CONFIRM_INDEX_MIGRATION_START` to run this task') unless ENV['CONFIRM_INDEX_MIGRATION_START']

    index_names.each do |index_name|
      GovukIndex::PopularityUpdater.migrate(index_name)
    end
  end

  desc "Migrates an index group to a new index.

Seamlessly creates a new index in the same index_group using the latest
schema, copies over all data and switches over the index_groups alias to point
to the new index on success. For safety it verifies that the new index
contains exactly the same number of documents as the original index.

You should run this task if the index schema has changed.
"
  task :migrate_index do
    index_names.each do |index_name|
      Indexer::BulkLoader.new(search_config, index_name).load_from_current_index
    end
  end

  desc "Switches an index group to a new index WITHOUT transferring the data"
  task :switch_to_empty_index do
    # Note that this task will effectively clear out the index, so shouldn't be
    # run on production without some serious consideration.
    index_names.each do |index_name|
      index_group = search_server.index_group(index_name)
      index_group.switch_to index_group.create_index
    end
  end

  desc "Switches an index group to a specific index WITHOUT transferring data"
  task :switch_to_named_index, [:new_index_name] do |_, args|
    # This makes no assumptions on the contents of the new index.
    # If it has been restored from a snapshot, you should check that the
    # index is fully recovered first. See :check_recovery.
    raise "The new index name must be supplied" unless args.new_index_name

    new_index_name = args.new_index_name

    index_names.each do |index_name|
      if new_index_name.include?(index_name)
        puts "Switching #{index_name} -> #{args.new_index_name}"
        index_group = search_server.index_group(index_name)
        index_group.switch_to(index_group.index_for_name(new_index_name))
      end
    end
  end

  desc "Migrates from an index with the actual index name to an alias"
  task :migrate_from_unaliased_index do
    # WARNING: this is potentially dangerous, and will leave the search
    # unavailable for a very short (sub-second) period of time
    index_names.each do |index_name|
      Indexer::BulkLoader.new(search_config, index_name).load_from_current_unaliased_index
    end
  end

  desc "Cleans out old indices"
  task :clean do
    # as we only want to clean the indices for the versions that matches from the overnight copy task
    # if we didn't check this we could potentially attempt to delete one of the new indices as we are importing
    # data into it.
    version = ENV.fetch('RUMMAGER_VERSION', '1.7')
    if version == ELASTICSEARCH_VERSION
      index_names.each do |index_name|
        search_server.index_group(index_name).clean
      end
    end
  end

  desc "Check whether a restored index has recovered"
  task :check_recovery, [:index_name] do |_, args|
    raise "An 'index_name' must be supplied" unless args.index_name

    puts SearchIndices::Index.index_recovered?(
      base_uri: elasticsearch_uri,
      index_name: args.index_name
    )
  end
end
