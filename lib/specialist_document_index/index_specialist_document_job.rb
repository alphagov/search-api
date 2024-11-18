require "byebug"
module SpecialistDocumentIndex
  class IndexSpecialistDocumentJob < BaseJob
    notify_of_failures

    def perform(document)
      Services.statsd_client.increment("specialist_document_index.sidekiq-consumed")
      processor = Index::ElasticsearchProcessor.specialist_document
      processor.save(DocumentPresenter.new(document))
      responses = processor.commit
      Services.statsd_client.increment("specialist_document_index.elasticsearch.index")
    rescue Exception # rubocop:disable Lint/RescueException
      Services.statsd_client.increment("specialist_document_index.sidekiq-retry")
      raise
    end
  end
end
