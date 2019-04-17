require 'gds_api/email_alert_api'

module Indexer
  class MetadataTaggerNotificationWorker < BaseWorker
    notify_of_failures

    def perform(item_in_search, metadata)
      send_notification(item_in_search["_source"], metadata)
    end

    def send_notification(document, metadata)
      payload = email_alert_api_payload(document, metadata)

      begin
        self.class.email_alert_api.send_alert(payload)
        logger.info "Notification sent for #{payload}"
      rescue GdsApi::HTTPConflict
        logger.info "Email alert API returned 409 conflict for #{payload}"
      end
    end

    def email_alert_api_payload(document, metadata)
      {
        title: document["title"],
        description: document["description"],
        change_note: "This publication has just been added to the EU Exit business guidance finder on GOV.UK.",
        subject: document["title"],
        tags: metadata,
        links: {
          content_id: document["content_id"],
          organisations: document["organisation_content_ids"],
          taxons: document["taxons"],
        },
        urgent: true,
        document_type: document["content_store_document_type"],
        email_document_supertype: "other",
        government_document_supertype: "other",
        content_id: document["content_id"],
        public_updated_at: Time.now.iso8601,
        publishing_app: document.fetch("publishing_app", "search-api"),
        base_path: document["link"],
        priority: "high",
      }
    end

    def self.email_alert_api
      @email_alert_api ||= GdsApi::EmailAlertApi.new(
        Plek.current.find('email-alert-api'),
        bearer_token: ENV['EMAIL_ALERT_API_BEARER_TOKEN'] || 'example123'
      )
    end
  end
end
