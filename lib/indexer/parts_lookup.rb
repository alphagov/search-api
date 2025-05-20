module Indexer
  # assumes it's run after AttachmentsLookup
  class PartsLookup
    def initialize
      @logger = Logging.logger[self]
    end

    def self.prepare_parts(doc_hash, return_raw_body: false)
      new.prepare_parts(doc_hash, return_raw_body)
    end

    def prepare_parts(doc_hash, return_raw_body)
      return doc_hash unless doc_hash["parts"].nil?

      attachments = doc_hash.fetch("attachments", []).select { |a| can_be_a_part?(doc_hash, a) }
      return doc_hash if attachments.empty?

      doc_hash.merge("parts" => attachments.map { |a| present_part(a, return_raw_body) })
    end

  private

    def present_part(attachment, return_raw_body)
      body = attachment["content"]
      {
        "slug" => attachment["url"].split("/").last,
        "link" => attachment["url"],
        "title" => attachment["title"],
        "body" => return_raw_body ? body : body.truncate(75, omission: "…", separator: " "),
      }
    end

    def can_be_a_part?(doc_hash, attachment)
      return false unless attachment["url"]
      return false unless attachment["content"]

      # we don't index full part URLs, only slugs, so we need to
      # ensure the full prefix matches
      return false unless attachment["url"].start_with? doc_hash["link"]

      true
    end
  end
end
