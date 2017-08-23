module GovukIndex
  class PopularityUpdater
    SCROLL_BATCH_SIZE = 500
    PROCESSOR_BATCH_SIZE = 25
    TIMEOUT_SECONDS = 30

    def self.update(index_name)
      new(
        source_index: index_name,
        destination_index: index_name,
      ).run
    end

    # This task is designed to migrate data when the schema changes, It waits for the
    # queued jobs to be processed, this is done by monitoring the sidekiq queue and workers.
    # This process should be closely monitored as it is not guaranteed to work.
    def self.migrate(index_name)
      index_group = SearchConfig.instance.search_server.index_group(index_name)
      new_index = index_group.create_index
      index_group.current.with_lock do
        new(
          source_index: index_group.current.real_name,
          destination_index: new_index.real_name,
        ).run
        # wait for queued tasks to be started
        sleep 1 while(Sidekiq::Queue.new(GovukIndex::PopularityWorker::QUEUE_NAME).size > 0) # rubocop: disable Style/ZeroLengthPredicate
        # wait for started tasks to be finished
        sleep 1 while(Sidekiq::Workers.new.any? { |_, _, work| work['queue'] == GovukIndex::PopularityWorker::QUEUE_NAME })
        index_group.switch_to(new_index)
      end
    end

    def initialize(source_index:, destination_index:)
      @source_index = source_index
      @destination_index = destination_index
    end

    def run
      scroll_enumerator.each_slice(PROCESSOR_BATCH_SIZE) do |documents|
        PopularityWorker.perform_async(documents, @destination_index)
      end
    end

  private

    def scroll_enumerator
      ScrollEnumerator.new(
        client: Services.elasticsearch(hosts: SearchConfig.instance.base_uri, timeout: TIMEOUT_SECONDS),
        index_names: @source_index,
        search_body: { query: { match_all: {} } },
        batch_size: SCROLL_BATCH_SIZE
      ) do |record|
        {
          identifier: record.slice(*%w{_id _type _version}),
          document: record.fetch('_source'),
        }
      end
    end
  end
end
