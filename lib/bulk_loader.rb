class BulkLoader
  def initialize(search_config, index_name, options = {})
    @search_config = search_config
    @index_name = index_name
    @batch_size = options[:batch_size] || 1024
  end

  def load_from(iostream)
    new_index = index_group.create_index
    old_index = index_group.current_real

    if old_index
      old_index.with_lock do
        do_indexing(new_index, iostream)

        # Switch aliases inside the lock so we avoid a race condition where a
        # new index exists, but the old index is available for writes
        index_group.switch_to new_index

        old_index.close
      end
    else
      index_group.switch_to new_index
      do_indexing(new_index, iostream)
    end
  end

private
  def do_indexing(index, iostream)
    iostream.each_line.each_slice(@batch_size) do |lines|
      index.bulk_index(lines.join(""))
    end
  end

  def search_server
    @search_server ||= @search_config.search_server
  end

  def index_group
    @index_group ||= search_server.index_group(@index_name)
  end
end