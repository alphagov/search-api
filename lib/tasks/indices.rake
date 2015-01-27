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

  desc "Migrates an index group to a new index, optionally extracting entities (default false)

Seamlessly creates a new index in the same index_group using the latest
schema, copies over all data and switches over the index_groups alias to point
to the new index on success. For safety it verifies that the new index
contains exactly the same number of documents as the original index.

You should run this task if the index schema has changed.

The extract_entities option allows you to enable entity_extraction during the
index migration. This is a potentially slow operation for an entire index
(10ms * 100k docs = circa 15 mins). Normally you don't want to do this because
the entities data will not change, however if you want to rebuild the entities
data for some reason, you can enable this flag.
"
  task :migrate_index, [:extract_entities] do |t, args|
    extract_entities = (args[:extract_entities] || "") =~ /\A(y|true|1|yes)\Z/
    index_names.each do |index_name|
      index_group = search_server.index_group(index_name)

      new_index = index_group.create_index
      old_index = index_group.current_real

      if old_index
        old_index.with_lock do
          new_index.populate_from(old_index, {extract_entities: extract_entities})

          # Now bulk inserts fail if any of their operations fail (de47247),
          # and now we lock the old index to avoid any writes (87a7c60), the
          # document counts should always match if we get to this point without
          # throwing an exception, but it's a nice safeguard to have
          new_count = new_index.all_documents.size
          old_count = old_index.all_documents.size
          unless new_count == old_count
            logger.error(
              "Population miscount: new index has #{new_count} documents, " +
              "while old index has #{old_count}."
            )
            raise RuntimeError, "Population count mismatch"
          end

          # Switch aliases inside the lock so we avoid a race condition where a
          # new index exists, but the old index is available for writes
          index_group.switch_to new_index

          old_index.close
        end
      else
        index_group.switch_to new_index
      end
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

  desc "Migrates from an index with the actual index name to an alias"
  task :migrate_from_unaliased_index, [:extract_entities] do |t, args|
    extract_entities = (args[:extract_entities] || "") =~ /\A(y|true|1|yes)\Z/
    # WARNING: this is potentially dangerous, and will leave the search
    # unavailable for a very short (sub-second) period of time

    index_names.each do |index_name|
      index_group = search_server.index_group(index_name)

      real_index_name = index_group.current.real_name
      unless real_index_name == index_name
        # This task only makes sense if we're migrating from an unaliased index
        raise "Expecting index name #{index_name.inspect}; found #{real_index_name.inspect}"
      end

      logger.info "Creating new #{index_name} index..."
      new_index = index_group.create_index
      logger.info "...index '#{new_index.real_name}' created"

      logger.info "Populating new #{index_name} index..."
      new_index.populate_from(index_group.current, {extract_entities: extract_entities})
      logger.info "...index populated."

      logger.info "Deleting #{index_name} index..."
      index_group.send :delete, CGI.escape(index_name)
      logger.info "...deleted."

      logger.info "Switching #{index_name}..."
      index_group.switch_to new_index
      logger.info "...switched"
    end
  end

  desc "Cleans out old indices"
  task :clean do
    index_names.each do |index_name|
      search_server.index_group(index_name).clean
    end
  end
end
