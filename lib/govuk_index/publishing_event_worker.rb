require "indexer/workers/base_worker"
require 'govuk_index/elasticsearch_presenter'
require 'govuk_index/elasticsearch_saver'

module GovukIndex
  class ValidationError < StandardError; end

  class PublishingEventWorker < Indexer::BaseWorker
    notify_of_failures

    def perform(payload)
      Services.statsd_client.increment('govuk_index.sidekiq-consumed')
      presenter = ElasticsearchPresenter.new(payload)
      presenter.valid!
      ElasticsearchSaver.new.save(presenter)
    # Rescuing as we don't want to retry this class of error
    rescue ValidationError => e
      Airbrake.notify_or_ignore(
        e,
        parameters: {
          message_body: payload,
        }
      )
    # Rescuing exception to guarantee we capture all Sidekiq retries
    rescue Exception # rubocop:disable Lint/RescueException
      Services.statsd_client.increment('govuk_index.sidekiq-retry')
      raise
    end
  end
end
