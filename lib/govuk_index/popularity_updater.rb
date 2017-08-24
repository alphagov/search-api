module GovukIndex
  class PopularityUpdater < Updater
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

    def worker
      PopularityWorker
    end

    def search_body
      { query: { match_all: {} } }
    end
  end
end
