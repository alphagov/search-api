module Indexer
  class AttachmentsLookup
    def initialize
      @logger = Logging.logger[self]
    end

    def self.prepare_attachments(doc_hash)
      new.prepare_attachments(doc_hash)
    end

    def prepare_attachments(doc_hash)
      return doc_hash if doc_hash["attachments"].nil?

      doc_hash.merge("attachments" => doc_hash["attachments"].map { |a| present_attachment(a) }.compact)
    end

  private

    def present_attachment(attachment)
      return if attachment.fetch("locale", "en") != "en"

      content = nil
      if attachment["attachment_type"] == "html"
        content = fetch_attachment_content(attachment)
        return unless content
      end

      {
        "url" => attachment["url"],
        "title" => attachment["title"],
        "isbn" => attachment["isbn"],
        "unique_reference" => attachment["unique_reference"],
        "command_paper_number" => attachment["command_paper_number"],
        "hoc_paper_number" => attachment["hoc_paper_number"],
        "content" => content,
      }.compact
    end

    def fetch_attachment_content(attachment)
      return unless attachment.key? "url"

      part = fetch_from_publishing_api(attachment["url"])
      return unless part

      html_body = part.dig("details", "body")

      Loofah.document(html_body).to_text(encode_special_chars: false).squish
    end

    def fetch_from_publishing_api(base_path)
      content_id = Indexer.find_content_id(base_path, @logger)
      return unless content_id

      begin
        GdsApi.with_retries(maximum_number_of_attempts: 5) do
          Services.publishing_api.get_live_content(content_id)
        end
      rescue GdsApi::TimedOutException => e
        @logger.error("Timeout fetching content item for #{content_id}")
        GovukError.notify(
          e,
          extra: {
            error_message: "Timeout fetching content item",
            content_id: content_id,
          },
        )
        raise Indexer::PublishingApiError
      rescue GdsApi::HTTPNotFound => e
        # If the Content ID no longer exists in the Publishing API, there isn't really much
        # we can do at this point. There doesn't seem to be any compelling reason to record
        # this in Sentry as there is no bug to fix.
        @logger.error("HTTP not found error fetching content item for #{content_id}: #{e.message}")
        nil
      rescue GdsApi::HTTPErrorResponse => e
        @logger.error("HTTP error fetching content item for #{content_id}: #{e.message}")
        # We capture all GdsApi HTTP exceptions here so that we can send them
        # manually to Sentry. This allows us to control the message and parameters
        # such that errors are grouped in a sane manner.
        GovukError.notify(
          e,
          extra: {
            message: "HTTP error fetching content item",
            content_id: content_id,
            error_code: e.code,
            error_message: e.message,
            error_details: e.error_details,
          },
        )
        raise Indexer::PublishingApiError
      end
    end
  end
end
