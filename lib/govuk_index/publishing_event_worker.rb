module GovukIndex
  class ValidationError < StandardError; end
  class ElasticsearchError < StandardError; end
  class MultipleMessagesInElasticsearchResponse < StandardError; end

  class PublishingEventWorker < Indexer::BaseWorker
    notify_of_failures

    def perform(routing_key, payload)
      actions = ElasticsearchProcessor.new
      process_action(actions, routing_key, payload)
      response = actions.commit
      process_response(response)
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

  private

    def process_action(actions, routing_key, payload)
      Services.statsd_client.increment('govuk_index.sidekiq-consumed')
      presenter = ElasticsearchPresenter.new(payload)
      presenter.valid!

      if routing_key =~ /\.unpublish$/ && !presenter.withdrawn?
        actions.delete(presenter)
      else
        actions.save(presenter)
      end
    end

    def process_response(response)
      # we are only expecting to process a single message at a time
      if response['items'].count > 1
        Services.statsd_client.increment('govuk_index.elasticsearch.multiple_responses')
        raise MultipleMessagesInElasticsearchResponse
      end

      item = response['items'].first
      action_type, details = *item.first # item is a hash with a single key, value pair

      if (200..399).cover?(details['status'])
        Services.statsd_client.increment("govuk_index.elasticsearch.#{action_type}")
      elsif action_type == 'delete' && details['status'] == 404 # failed while attempting to delete missing record so just ignore it
        Services.statsd_client.increment('govuk_index.elasticsearch.already_deleted')
      elsif details['status'] == 409
        # A version conflict indicates that messages were processed out of
        # order. This is not expected to happen often but is safe to ignore.
        Services.statsd_client.increment('govuk_index.elasticsearch.version_conflict')
      else
        Services.statsd_client.increment("govuk_index.elasticsearch.#{action_type}_error")
        raise ElasticsearchError, action_type: action_type, details: details
      end
    end
  end
end
