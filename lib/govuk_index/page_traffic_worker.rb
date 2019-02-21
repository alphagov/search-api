module GovukIndex
  class PageTrafficWorker < Indexer::BaseWorker
    BULK_INDEX_TIMEOUT = 60
    QUEUE_NAME = 'bulk'.freeze
    sidekiq_options queue: QUEUE_NAME

    def self.perform_async(records, destination_index)
      data = Base64.encode64(Zlib::Deflate.deflate(Sidekiq.dump_json(records)))
      super(data, destination_index)
    end

    def perform(data, destination_index)
      records = Sidekiq.load_json(Zlib::Inflate.inflate(Base64.decode64(data)))

      actions = Index::ElasticsearchProcessor.new(client: GovukIndex::Client.new(timeout: BULK_INDEX_TIMEOUT, index_name: destination_index))

      records.each_slice(2) do |identifier, document|
        identifier['index'].merge('_type' => 'generic-document')
        document['document_type'] = 'page_traffic'
        actions.raw(identifier, document)
      end

      actions.commit
    end
  end
end
