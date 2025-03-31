module GovukIndex
  class ElasticsearchRetryError < StandardError; end

  class ElasticsearchInvalidResponseItemCount < StandardError; end

  class MissingTextHtmlContentType < StandardError; end

  class MultipleMessagesInElasticsearchResponse < StandardError; end

  class NotFoundError < StandardError; end

  class UnknownDocumentTypeError < StandardError; end

  class NotIdentifiable < StandardError; end

  class MissingExternalUrl < StandardError; end

  DOCUMENT_TYPES_WITHOUT_BASE_PATH =
    %w[
      contact
      role_appointment
      world_location

      #
      role
      document
      types
      ambassador_role
      board_member_role
      chief_professional_officer_role
      chief_scientific_officer_role
      chief_scientific_advisor_role
      deputy_head_of_mission_role
      governor_role
      high_commissioner_role
      military_role
      ministerial_role
      special_representative_role
      traffic_commissioner_role
      worldwide_office_staff_role
    ].freeze

  class PublishingEventMessageHandler
    def initialize
      @logger = Logging.logger[self]
    end

    def process(messages)
      processor = Index::ElasticsearchProcessor.govuk

      messages.each do |routing_key, payload|
        process_action(processor, routing_key, payload)
      end

      responses = processor.commit

      (responses || []).each do |response|
        process_response(response, messages)
      end
    end

  private

    attr_reader :logger

    def process_action(processor, routing_key, payload)
      logger.debug("Processing #{routing_key}: #{payload}")

      type_mapper = DocumentTypeMapper.new(payload)

      presenter = if type_mapper.unpublishing_type?
                    ElasticsearchDeletePresenter.new(payload:)
                  else
                    ElasticsearchPresenter.new(
                      payload: PayloadPreparer.new(payload).prepare,
                      type_mapper:,
                    )
                  end

      presenter.valid!

      identifier = "#{presenter.link} #{presenter.type || "'unmapped type'"}"

      if type_mapper.unpublishing_type?
        logger.info("#{routing_key} -> DELETE #{identifier}")
        processor.delete(presenter)
      elsif MigratedFormats.non_indexable?(presenter.format, presenter.base_path)
        logger.info("#{routing_key} -> BLOCKLISTED #{identifier} (non-indexable)")
      elsif !document_in_english?(payload) && !is_welsh_hmrc_contact?(payload)
        logger.info("#{routing_key} -> BLOCKLISTED #{identifier} (non-english, and not Welsh HMRC contact)")
      elsif MigratedFormats.indexable?(presenter.format, presenter.base_path)
        logger.info("#{routing_key} -> INDEX #{identifier}")
        processor.save(presenter)
      else
        logger.info("#{routing_key} -> UNKNOWN #{identifier}")
      end

    # Rescuing as we don't want to retry this class of error
    rescue NotIdentifiable => e
      return if DOCUMENT_TYPES_WITHOUT_BASE_PATH.include?(payload["document_type"])

      GovukError.notify(e, extra: { message_body: payload })
      # Unpublishing messages for something that does not exist may have been
      # processed out of order so we don't want to notify errbit but just allow
      # the process to continue
    rescue NotFoundError
      logger.info("#{payload['base_path']} could not be found.")
      Services.statsd_client.increment("govuk_index.not-found-error")
    rescue UnknownDocumentTypeError
      logger.info("#{payload['document_type']} document type is not known.")
      Services.statsd_client.increment("govuk_index.unknown-document-type")
    end

    def process_response(response, messages)
      messages_with_error = []
      if response["items"].count > 1
        Services.statsd_client.increment("govuk_index.elasticsearch.multiple_responses")
      end

      if response["items"].count != messages.count
        raise ElasticsearchInvalidResponseItemCount, "received #{response['items'].count} expected #{messages.count}"
      end

      response["items"].zip(messages).each do |response_for_message, message|
        messages_with_error << message unless Index::ResponseValidator.new(namespace: "govuk_index").valid?(response_for_message)
      end

      if messages_with_error.any?
        # raise an error so that all messages are retried.
        # NOTE: versioned ES actions can be performed multiple with a consistent result.
        raise ElasticsearchRetryError.new(
          reason: "Elasticsearch failures",
          messages: "#{messages_with_error.count} of #{messages.count} failed - see ElasticsearchError's for details",
        )
      end
    end

    def is_welsh_hmrc_contact?(payload)
      hmrc_contact = payload["document_type"] == "hmrc_contact"
      welsh_locale = payload["locale"] == "cy"

      hmrc_contact && welsh_locale
    end

    def document_in_english?(payload)
      payload.fetch("locale", "en") == "en"
    end
  end
end
