module GovukIndex
  class ElasticsearchError < StandardError; end
  class MissingTextHtmlContentType < StandardError; end
  class MultipleMessagesInElasticsearchResponse < StandardError; end
  class NotFoundError < StandardError; end
  class UnknownDocumentTypeError < StandardError; end
  class ValidationError < StandardError; end

  class PublishingEventWorker < Indexer::BaseWorker
    notify_of_failures

    def perform(routing_key, payload)
      actions = ElasticsearchProcessor.new
      process_action(actions, routing_key, payload)
      response = actions.commit
      process_response(response) if response
    # Rescuing as we don't want to retry this class of error
    rescue ValidationError => e
      Airbrake.notify_or_ignore(
        e,
        parameters: {
          message_body: payload,
        }
      )
    # Unpublishing messages for something that does not exist may have been
    # processed out of order so we don't want to notify errbit but just allow
    # the process to continue
    rescue NotFoundError
      logger.info("#{payload['base_path']} could not be found.")
      Services.statsd_client.increment('govuk_index.not-found-error')
    rescue UnknownDocumentTypeError
      logger.info("#{payload['document_type']} document type is not known.")
      Services.statsd_client.increment('govuk_index.unknown-document-type')
    # Rescuing exception to guarantee we capture all Sidekiq retries
    rescue Exception # rubocop:disable Lint/RescueException
      Services.statsd_client.increment('govuk_index.sidekiq-retry')
      raise
    end

  private

    def process_action(actions, routing_key, payload)
      logger.debug("Processing #{routing_key}: #{payload}")
      Services.statsd_client.increment('govuk_index.sidekiq-consumed')

      presenter = ElasticsearchPresenter.new(
        payload: payload,
        type_inferer: DocumentTypeInferer,
      )
      presenter.valid!

      if presenter.unpublishing_type?
        logger.info("#{routing_key} -> DELETE #{presenter.base_path} #{presenter.type}")
        actions.delete(presenter)
      elsif MigratedFormats.indexable?(presenter.format) && payload['publishing_app'] != 'smartanswers'
        logger.info("#{routing_key} -> INDEX #{presenter.base_path} #{presenter.type}")
        actions.save(presenter)
      else
        logger.info("#{routing_key} -> SKIPPED #{presenter.base_path} #{presenter.type}")
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
      status = details['status']

      if (200..399).cover?(status)
        logger.debug("Processed #{action_type} with status #{status}")
        Services.statsd_client.increment("govuk_index.elasticsearch.#{action_type}")
      elsif action_type == 'delete' && details['status'] == 404 # failed while attempting to delete missing record so just ignore it
        logger.info("Tried to delete a document that wasn't there; ignoring.")
        Services.statsd_client.increment('govuk_index.elasticsearch.already_deleted')
      elsif details['status'] == 409
        # A version conflict indicates that messages were processed out of
        # order. This is not expected to happen often but is safe to ignore.
        logger.info("#{action_type} version is outdated; ignoring.")
        Services.statsd_client.increment('govuk_index.elasticsearch.version_conflict')
      else
        logger.error("#{action_type} not processed: status #{status}")
        Services.statsd_client.increment("govuk_index.elasticsearch.#{action_type}_error")
        raise ElasticsearchError, action_type: action_type, details: details
      end
    end
  end
end
