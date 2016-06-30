namespace :rummager do
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

  desc "Migrates an index group to a new index.

Seamlessly creates a new index in the same index_group using the latest
schema, copies over all data and switches over the index_groups alias to point
to the new index on success. For safety it verifies that the new index
contains exactly the same number of documents as the original index.

You should run this task if the index schema has changed.

"
  task :migrate_index do
    require 'indexer/bulk_loader'

    index_names.each do |index_name|
      # Batch concurrency reduced from 12 to 3 until publishing api can handle the load.
      Indexer::BulkLoader.new(search_config, index_name, batch_concurrency: 3).load_from_current_index
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

    require 'indexer/bulk_loader'

    index_names.each do |index_name|
      Indexer::BulkLoader.new(search_config, index_name).load_from_current_unaliased_index
    end
  end

  desc "Cleans out old indices"
  task :clean do
    index_names.each do |index_name|
      search_server.index_group(index_name).clean
    end
  end

  desc "Check whether a restored index has recovered"
  task :check_recovery, [:index_name] do |_, args|
    raise "An 'index_name' must be supplied" unless args.index_name

    require 'index'

    puts SearchIndices::Index.index_recovered?(
      base_uri: elasticsearch_uri,
      index_name: args.index_name
    )
  end
end
