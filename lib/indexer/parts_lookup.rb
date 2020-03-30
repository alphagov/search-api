module Indexer
  class PartsLookup
    def initialize
      @logger = Logging.logger[self]
    end

    def self.prepare_parts(doc_hash)
      new.prepare_parts(doc_hash)
    end

    def prepare_parts(doc_hash)
      return doc_hash unless doc_hash["parts"].nil?

      attachments = doc_hash.fetch("attachments", []).select { |a| a["attachment_type"] == "html" }
      return doc_hash if attachments.empty?

      doc_hash.merge("parts" => attachments.map { |a| fetch_attachment_part(a) })
    end

  private

    def find_content_id(doc_hash)
      Indexer::find_content_id(doc_hash, @logger)
    end

    def fetch_attachment_part(attachment)
      part = fetch_from_publishing_api(attachment["url"])

      {
        "slug" => attachment["url"].split("/").last,
        "title" => attachment["title"],
        "body" => summarise(part.dig("details", "body")),
      }
    end

    def summarise(html_body)
      return unless html_body

      Loofah.document(html_body)
        .to_text(encode_special_chars: false).squish
        .truncate(75, omission: "…", separator: " ")
    end

    def fetch_from_publishing_api(base_path)
      content_id = find_content_id(base_path)

      begin
        GdsApi.with_retries(maximum_number_of_attempts: 5) do
          Services.publishing_api.get_live_content(content_id)
        end
      rescue GdsApi::TimedOutException => e
        @logger.error("Timeout fetching content item for #{content_id}")
        GovukError.notify(e,
                          extra: {
                            error_message: "Timeout fetching content item",
                            content_id: content_id,
                          })
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
        GovukError.notify(e,
                          extra: {
                            message: "HTTP error fetching content item",
                            content_id: content_id,
                            error_code: e.code,
                            error_message: e.message,
                            error_details: e.error_details,
                          })
        raise Indexer::PublishingApiError
      end
    end
  end
end
