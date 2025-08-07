module GovukIndex
  class PayloadPreparer
    def initialize(payload)
      @payload = payload
    end

    def prepare
      return @payload unless @payload["details"]

      payload = prepare_attachments(@payload)
      prepare_parts(payload)
    end

  private

    def prepare_attachments(payload)
      return payload if payload["details"].fetch("attachments", []).empty?

      details = Indexer::AttachmentsLookup.prepare_attachments(payload["details"])

      merge_details(payload, "attachments", details["attachments"])
    end

    def prepare_parts(payload)
      parts = payload["details"]["parts"]

      if parts && parts.any?
        updated_parts = parts.map do |part|
          next part if part["link"]

          link = "#{payload['base_path']}/#{part['slug']}"
          part.merge("link" => link)
        end

        return merge_details(payload, "parts", updated_parts)
      end

      details = Indexer::PartsLookup.prepare_parts(
        payload["details"].merge("link" => payload["base_path"]),
        return_raw_body: true,
      )
      return payload if details.fetch("parts", []).empty?

      presented_parts = details["parts"].map do |part|
        {
          "slug" => part["slug"],
          "title" => part["title"],
          "link" => part["link"],
          "body" => [{ "content_type" => "text/html", "content" => part["body"] }],
        }
      end

      merge_details(payload, "parts", presented_parts)
    end

    def merge_details(payload, field, value)
      details = payload["details"]
      payload.merge("details" => details.merge(field => value))
    end
  end
end
