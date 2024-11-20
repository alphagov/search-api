module GovukIndex
  class PageTrafficJob < BaseJob
    BULK_INDEX_TIMEOUT = 60
    QUEUE_NAME = "bulk".freeze
    sidekiq_options queue: QUEUE_NAME

    # Wait for all tasks for the given queue/job class combination to be
    # completed before continuing
    def self.wait_until_processed(max_timeout: 2 * 60 * 60)
      Timeout.timeout(max_timeout) do
        # wait for all queued tasks to be started
        sleep 1 while Sidekiq::Queue.new(self::QUEUE_NAME).any? { |job| job.klass == to_s }

        # wait for started tasks to be finished
        sleep 1 while active_jobs?
      end
    end

    def self.active_jobs?
      # This code makes use of Sidekiq::API which is not advised for application
      # usage and is hard to test, be very careful changing it.
      Sidekiq::WorkSet.new.any? do |_, _, work|
        work.queue == self::QUEUE_NAME && work.payload["class"] == to_s
      end
    end

    def self.perform_async(records, destination_index, cluster_key)
      data = Base64.encode64(Zlib::Deflate.deflate(Sidekiq.dump_json(records)))
      super(data, destination_index, cluster_key)
    end

    def perform(data, destination_index, cluster_key)
      records = Sidekiq.load_json(Zlib::Inflate.inflate(Base64.decode64(data)))
      cluster = Clusters.get_cluster(cluster_key)
      actions = Index::ElasticsearchProcessor.new(client: GovukIndex::Client.new(timeout: BULK_INDEX_TIMEOUT, index_name: destination_index, clusters: [cluster]))

      records.each_slice(2) do |identifier, document|
        identifier["index"] = identifier["index"].merge("_type" => "generic-document")
        document["document_type"] = "page_traffic"
        actions.raw(identifier, document)
      end

      actions.commit
    end
  end
end
