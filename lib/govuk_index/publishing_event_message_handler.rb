module GovukIndex
  class PublishingEventMessageHandler
    class ElasticsearchRetryError < StandardError; end

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

    def initialize(routing_key, payload)
      @routing_key = routing_key
      @payload = payload
      @logger = Logging.logger[self]
    end

    def self.call(...)
      new(...).call
    end

    def call
      processor = Index::ElasticsearchProcessor.govuk
      process_action(processor)
      response = processor.commit

      process_response(response) if response.present?
    end

  private

    attr_reader :logger, :routing_key, :payload

    def process_action(processor)
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
      elsif !document_in_english? && !is_welsh_hmrc_contact?
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

    def process_response(response)
      response_for_message = response.dig(0, "items", 0)

      unless Index::ResponseValidator.new(namespace: "govuk_index").valid?(response_for_message)
        raise ElasticsearchRetryError.new(reason: "Elasticsearch failures")
      end
    end

    def is_welsh_hmrc_contact?
      hmrc_contact = payload["document_type"] == "hmrc_contact"
      welsh_locale = payload["locale"] == "cy"

      hmrc_contact && welsh_locale
    end

    def document_in_english?
      payload.fetch("locale", "en") == "en"
    end
  end
end
