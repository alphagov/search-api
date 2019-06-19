module GovukIndex
  class PageTrafficLoader
    def initialize(iostream_batch_size: 250)
      @iostream_batch_size = iostream_batch_size
      @logger = Logging.logger[self]
      @logger.level = :info
    end

    def load_from(iostream)
      Clusters.active.each do |cluster|
        new_index = index_group(cluster).create_index
        @logger.info "Created index #{new_index.real_name}"

        old_index = index_group(cluster).current_real
        @logger.info "Old index #{old_index.real_name}"

        old_index.with_lock do
          @logger.info "Indexing to #{new_index.real_name}"

          in_even_sized_batches(iostream) do |lines|
            GovukIndex::PageTrafficWorker.perform_async(lines, new_index.real_name, cluster.key)
          end

          GovukIndex::PageTrafficWorker.wait_until_processed
          new_index.commit
        end

        # We need to switch the aliases without a lock, since
        # read_only_allow_delete prevents aliases being changed
        # The page traffic loader is is a daily process, so there
        # won't be a race condition
        index_group(cluster).switch_to(new_index)
      end
    end

  private

    # Breaks the given input stream into batches of documents
    # This is due to ES recommendations for index optimisation
    # https://www.elastic.co/guide/en/elasticsearch/reference/2.4/docs-bulk.html
    def in_even_sized_batches(iostream, batch_size = @iostream_batch_size, &_block)
      iostream.each_line.each_slice(batch_size * 2) do |batch|
        yield(batch.map { |b| JSON.parse(b) })
      end
      iostream.pos = 0 # ensures we start at the beginning on next read.
    end

    def index_group(cluster)
      @index_group ||= {}
      @index_group[cluster.key] ||= SearchConfig.instance.search_server(cluster: cluster).index_group(
        SearchConfig.instance.page_traffic_index_name
      )
    end
  end
end
