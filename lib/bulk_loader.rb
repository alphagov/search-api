require 'time'

class BulkLoader
  def initialize(search_config, index_name, options = {})
    @search_config = search_config
    @index_name = index_name
    @batch_size = options[:batch_size] || 1024 * 1024
    @logger = options[:logger] || Logger.new(nil)
  end

  def load_from(iostream)
    new_index = index_group.create_index
    @logger.info "Created index #{new_index.real_name}"
    old_index = index_group.current_real
    @logger.info "Old index #{old_index.real_name}"

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
    @logger.info "Indexing to #{index.real_name}"
    total_lines = 0
    start_time = Time.now
    in_even_sized_batches(iostream) do |lines|
      index.bulk_index(lines.join(""))
      @logger.info "Sent #{lines.size} lines (#{byte_size(lines)} bytes)"
      total_lines += lines.size
    end
    elapsed_time = Time.now - start_time
    @logger.info "Indexed %s lines in %.2f seconds (%.2f lines/sec)" % [total_lines, elapsed_time, total_lines / elapsed_time]
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