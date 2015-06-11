require 'time'

class BulkLoader
  def initialize(search_config, index_name, options = {})
    @search_config = search_config
    @index_name = index_name
    @batch_size = options[:batch_size] || 256 * 1024
    @logger = options[:logger] || Logger.new(nil)
  end

  def load_from(iostream)
    new_index = index_group.create_index
    @logger.info "Created index #{new_index.real_name}"
    old_index = index_group.current_real
    if old_index.nil?
      @logger.info "No old index"
    else
      @logger.info "Old index #{old_index.real_name}"
    end

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

  def load_from_current_index
    new_index = index_group.create_index
    old_index = index_group.current_real

    if old_index
      old_index.with_lock do
        new_index.populate_from old_index

        # Now bulk inserts fail if any of their operations fail (de47247),
        # and now we lock the old index to avoid any writes (87a7c60), the
        # document counts should always match if we get to this point without
        # throwing an exception, but it's a nice safeguard to have
        new_count = new_index.all_documents.size
        old_count = old_index.all_documents.size
        unless new_count == old_count
          @logger.error(
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

private
  def do_indexing(index, iostream)
    @logger.info "Indexing to #{index.real_name}"
    total_lines = 0
    start_time = Time.now
    in_even_sized_batches(iostream) do |lines|
      index.bulk_index(lines.join(""), timeout_options)
      @logger.info "Sent #{lines.size} lines (#{byte_size(lines)} bytes)"
      total_lines += lines.size
    end
    elapsed_time = Time.now - start_time
    @logger.info "Indexed %s lines in %.2f seconds (%.2f lines/sec)" % [total_lines, elapsed_time, total_lines / elapsed_time]
  end

  def timeout_options
    {
      timeout: 30.0,
      open_timeout: 20.0
    }
  end

  def byte_size(lines)
    lines.inject(0) {|memo, l| memo + l.size}
  end

  # Breaks the given input stream into batches of line pairs of at least
  # `batch_size` bytes (including newlines). Always keeps line pairs together.
  # Yields each batch of lines.
  def in_even_sized_batches(iostream, batch_size=@batch_size, &block)
    chunk = []
    iostream.each_line.each_slice(2) do |command, document|
      chunk << command
      chunk << document
      if byte_size(chunk) >= batch_size
        yield chunk
        chunk = []
      end
    end
    yield chunk if chunk.any?
  end

  def search_server
    @search_server ||= @search_config.search_server
  end

  def index_group
    @index_group ||= search_server.index_group(@index_name)
  end
end
