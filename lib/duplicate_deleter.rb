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

  def call(content_ids)
    content_ids.each do |content_id|
      parser = SearchParameterParser.new({ "filter_content_id" => content_id }, schema)
      search_params = Search::QueryParameters.new(parser.parsed_params)
      results = searcher.run(search_params)

      if results[:results].count < 2
        io.puts "Skipping #{content_id} as less than 2 results found"
        next
      end

      types = results[:results].map { |a| a[:elasticsearch_type] }
      if types.uniq.count < 2
        io.puts "Skipping #{content_id} not enough uniq types"
        next
      end

      if !types.include?(type_to_delete)
        io.puts "Skipping #{content_id} as type to delete #{type_to_delete} not present in #{types.join(', ')}"
        next
      end

      ids = results[:results].map { |a| a[:_id] }
      if ids.uniq.count != 1
        io.puts "Skipping #{content_id} as multiple _id's detected #{ids.uniq.join(', ')}"
        next
      end

      index_names = results[:results].map { |a| a[:index] }
      if index_names.uniq.count != 1
        io.puts "Skipping #{content_id} as multiple indicies detected #{index_names.uniq.join(', ')}"
        next
      end

      Indexer::DeleteWorker.new.perform(index_names.first, type_to_delete, ids.first)
      io.puts "Deleted duplicate for content_id #{content_id}"
    end

  end
end
