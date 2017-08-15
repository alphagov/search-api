module Indexer
  class BulkLoader
    def initialize(search_config, index_name, options = {})
      @search_config = search_config
      @index_name = index_name
      @iostream_batch_size = options.fetch(:iostream_batch_size, 256 * 1024)
      @document_batch_size = options.fetch(:document_batch_size, 50)
      @batch_concurrency = options.fetch(:batch_concurrency, 12)
      @logger = Logging.logger[self]
      @logger.level = :info
    end

    def load_from(iostream)
      build_and_switch_index do |queue|
        in_even_sized_batches(iostream) do |lines|
          queue.push(lines.join(""))
        end
      end
    end

    def load_from_current_index
      build_and_switch_index do |queue|
        current_index = index_group.current_real
        if current_index
          current_index.all_documents(client_options: timeout_options).each_slice(@document_batch_size) do |documents|
            queue.push(documents.map(&:elasticsearch_export))
          end
        end
      end
    end

    def load_from_current_unaliased_index
      old_index = index_group.current
      real_old_index_name = old_index.real_name
      unless real_old_index_name == @index_name
        # This task only makes sense if we're migrating from an unaliased index
        raise "Expecting index name #{@index_name.inspect}; found #{real_old_index_name.inspect}"
      end

      new_index = index_group.create_index
      @logger.info "...index '#{new_index.real_name}' created"

      @logger.info "Populating new #{@index_name} index..."
      populate_index(new_index) do |queue|
        old_index.all_documents(client_options: timeout_options).each_slice(@document_batch_size) do |documents|
          queue.push(documents.map(&:elasticsearch_export))
        end
      end
      @logger.info "...index populated."

      @logger.info "Deleting #{@index_name} index..."
      index_group.send :delete, CGI.escape(@index_name)
      @logger.info "...deleted."

      @logger.info "Switching #{@index_name}..."
      index_group.switch_to new_index
      @logger.info "...switched"
    end

  private

    def build_and_switch_index(&producer_block)
      new_index = index_group.create_index
      @logger.info "Created index #{new_index.real_name}"
      old_index = index_group.current_real
      if old_index
        @logger.info "Old index #{old_index.real_name}"
        old_index.with_lock do
          populate_index(new_index, &producer_block)

          comparer = Indexer::Comparer.new(old_index.real_name, new_index.real_name)
          @logger.info "Starting comparer run.."
          @logger.info "Comparer results:"
          @logger.info comparer.run.inspect

          # Switch aliases inside the lock so we avoid a race condition where a
          # new index exists, but the old index is available for writes
          index_group.switch_to(new_index)
          old_index.close
        end
      else
        @logger.info "No old index"
        populate_index(new_index, &producer_block)
        index_group.switch_to(new_index)
      end
    end

    def populate_index(new_index, &_producer_block)
      @logger.info "Indexing to #{new_index.real_name}"
      q = Queue.new
      producer_complete = false

      threads = []
      @batch_concurrency.times do |_n|
        th = Thread.new do
          loop do
            begin
              documents = q.pop(true)
            rescue ThreadError => e
              raise unless e.message == "queue empty"
              break if producer_complete
              sleep 0.1
              retry
            end
            new_index.bulk_index(documents, timeout_options)
          end
        end
        threads << th
      end

      yield q
      producer_complete = true
      threads.each(&:join)

      new_index.commit
    end

    def timeout_options
      {
        timeout: 30.0
      }
    end

    def byte_size(lines)
      lines.inject(0) { |memo, l| memo + l.size }
    end

    # Breaks the given input stream into batches of line pairs of at least
    # `batch_size` bytes (including newlines). Always keeps line pairs together.
    # Yields each batch of lines.
    def in_even_sized_batches(iostream, batch_size = @iostream_batch_size, &_block)
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
end
