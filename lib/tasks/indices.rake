require 'rummager'

namespace :rummager do
  # this is needed to support the migration to ES 2.4
  ELASTICSEARCH_VERSION = '2.4'.freeze

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

  desc "Compare two indices with an option format filter"
  task :compare_govuk, :format do |_, args|
    filtered_format = args[:format]
    filtered_format = nil if filtered_format == 'all'
    comparer = Indexer::GovukIndexFieldComparer.new
    puts Indexer::Comparer.new(
      'mainstream',
      'govuk',
      field_comparer: comparer,
      ignore: %w(popularity is_withdrawn),
      filtered_format: filtered_format
    ).run
    puts comparer.stats
  end

  desc "Create a brand new indices and assign an alias if no alias currently exists"
  task :create_all_indices do
    index_names.each do |index_name|
      index_group = search_config.search_server.index_group(index_name)
      index = index_group.create_index
      index_group.switch_to(index) unless index_group.current_real
    end
  end

  desc "Create a brand new index and assign an alias if no alias currently exists"
  task :create_index, :index_name do |_, args|
    index_group = search_config.search_server.index_group(args[:index_name])
    index = index_group.create_index
    index_group.switch_to(index) unless index_group.current_real
  end

  desc "Lock the index for writes"
  task :lock do
    index_names.each do |index_name|
      SearchConfig.instance.search_server.index(index_name).lock
    end
  end

  desc "Unlock the index for writes"
  task :unlock do
    index_names.each do |index_name|
      SearchConfig.instance.search_server.index(index_name).unlock
    end
  end

  desc "Sync unmigrated data from mainstream into govuk

While we are migrating data to govuk, it is important that govuk has
all the data from mainstream in order for soring to be calculated
correctly
"
  task :sync_govuk do
    GovukIndex::SyncUpdater.update
  end

  desc "Update popularity data in indices.

Update all data in the index inplace (without locks) with the new popularity
data using sidekiq workers.

This does not update the schema.
"
  task :update_popularity do
    index_names.each do |index_name|
      GovukIndex::PopularityUpdater.update(index_name, process_all: ENV.key?('PROCESS_ALL_DATA'))
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

  desc "Cleans out old indices"
  task :clean do
    # as we only want to clean the indices for the versions that matches from the overnight copy task
    # if we didn't check this we could potentially attempt to delete one of the new indices as we are importing
    # data into it.
    index_names.each do |index_name|
      search_server.index_group(index_name).clean
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
