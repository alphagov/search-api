module GovukIndex
  class PayloadPreparer
    def initialize(payload)
      @payload = payload
    end

    def prepare
      return @payload unless @payload["details"]

      prepare_parts(@payload)
    end

  private

    def prepare_parts(payload)
      return payload unless payload["details"].fetch("parts", []).empty?

      details = Indexer::PartsLookup.prepare_parts(payload["details"], return_raw_body: true)
      return payload if details.fetch("parts", []).empty?

      payload["details"]["parts"] = details["parts"].map do |part|
        {
          "slug" => part["slug"],
          "title" => part["title"],
          "body" => [{ "content_type" => "text/html", "content" => part["body"] }],
        }
      end

      payload
    end
  end
end
