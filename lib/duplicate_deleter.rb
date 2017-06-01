require_relative "../app"

class DuplicateDeleter
  attr_reader :type_to_delete, :io
  def initialize(type_to_delete, io = STDOUT)
    @type_to_delete = type_to_delete
    @io = io
  end

  def search_config
    Rummager.settings.search_config
  end

  def searcher
    @searcher ||= begin
      unified_index = search_config.search_server.index_for_search(
        search_config.content_index_names
      )

      registries = Search::Registries.new(
        search_config.search_server,
        search_config
      )
      Search::Query.new(unified_index, registries)
    end
  end

  def schema
    @schema ||= CombinedIndexSchema.new(
      search_config.content_index_names,
      search_config.schema_config
    )
  end

  def call(ids, id_type: 'content_id')
    ids.each do |id|
      parser = SearchParameterParser.new({ "filter_#{id_type}" => id, 'fields' => ['content_id'] }, schema)
      search_params = Search::QueryParameters.new(parser.parsed_params)
      results = searcher.run(search_params)

      if results[:results].count < 2
        io.puts "Skipping #{id_type} #{id} as less than 2 results found"
        next
      end

      types = results[:results].map { |a| a[:elasticsearch_type] }
      if types.uniq.count < 2
        io.puts "Skipping #{id_type} #{id} not enough uniq types"
        next
      end

      if !types.include?(type_to_delete)
        io.puts "Skipping #{id_type} #{id} as type to delete #{type_to_delete} not present in #{types.join(', ')}"
        next
      end

      ids = results[:results].map { |a| a[:_id] }
      if ids.uniq.count != 1 && !results_contain_duplicate_contacts(results[:results], type_to_delete)
        io.puts "Skipping #{id_type} #{id} as multiple _id's detected #{ids.uniq.join(', ')}"
        next
      end

      content_ids = results[:results].map { |a| a['content_id'] }
      if content_ids.uniq.count != 1
        if results[:results].any? { |a| a[:elasticsearch_type] != type_to_delete && a['content_id'].nil? }
          io.puts "Skipping #{id_type} #{id} as there is another document indexed with a valid '_type' but a missing content ID"
          next
        elsif results[:results].any? { |a| a[:elasticsearch_type] == type_to_delete && !a['content_id'].nil? }
          io.puts "Skipping #{id_type} #{id} as multiple non-null content_id's detected #{content_ids.uniq.join(', ')}"
          next
        end
      end

      index_names = results[:results].map { |a| a[:index] }
      if index_names.uniq.count != 1
        io.puts "Skipping #{id_type} #{id} as multiple indices detected #{index_names.uniq.join(', ')}"
        next
      end

      item_to_delete = results[:results].detect { |a| a[:elasticsearch_type] == type_to_delete }
      if item_to_delete
        Indexer::DeleteWorker.new.perform(index_names.first, type_to_delete, item_to_delete[:_id])
        io.puts "Deleted duplicate for #{id_type} #{id}"
      else
        puts "Skipping #{id_type} #{id} as no duplicate with #{type_to_delete} can be found. This should " +
          "not happen, and might indicate a bug in the duplicate deleter, or a race condition, where some " +
          "other process has already deleted this item."
      end
    end
  end

private

  def results_contain_duplicate_contacts(results, type_to_delete)
    contact_results = results.select { |a| a[:elasticsearch_type] == "contact" }

    # The _id field for most content is the same as the link (including the leading `/`), but contacts have an _id
    # without a leading slash. It's possible for duplicate contacts to be created *with* a leading slash, so the
    # _id's do not match exactly.
    contact_results.size == 1 &&
      results.any? { |a| a[:elasticsearch_type] == type_to_delete && a[:_id] == "/" + contact_results.first[:_id] }
  end
end
