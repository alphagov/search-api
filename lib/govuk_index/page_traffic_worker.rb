module GovukIndex
  class PageTrafficWorker < Indexer::BaseWorker
    BULK_INDEX_TIMEOUT = 60
    QUEUE_NAME = 'bulk'.freeze
    sidekiq_options queue: QUEUE_NAME

    def self.perform_async(records, destination_index, cluster_key)
      data = Base64.encode64(Zlib::Deflate.deflate(Sidekiq.dump_json(records)))
      super(data, destination_index, cluster_key)
    end

    def perform(data, destination_index, cluster_key)
      records = Sidekiq.load_json(Zlib::Inflate.inflate(Base64.decode64(data)))
      cluster = Clusters.get_cluster(cluster_key)
      actions = Index::ElasticsearchProcessor.new(client: GovukIndex::Client.new(timeout: BULK_INDEX_TIMEOUT, index_name: destination_index, clusters: [cluster]))

      records.each_slice(2) do |identifier, document|
        identifier['index'] = identifier['index'].merge('_type' => 'generic-document')
        document['document_type'] = 'page_traffic'
        actions.raw(identifier, document)
      end

      actions.commit
    end
  end
end
