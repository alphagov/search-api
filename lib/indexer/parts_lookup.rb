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

      attachments = doc_hash.fetch("attachments", []).select { |a| !a["url"].nil? && !a["content"].nil? }
      return doc_hash if attachments.empty?

      doc_hash.merge("parts" => attachments.map { |a| present_part(a, return_raw_body) })
    end

  private

    def present_part(attachment, return_raw_body)
      body = attachment["content"]
      {
        "slug" => attachment["url"].split("/").last,
        "title" => attachment["title"],
        "body" => return_raw_body ? body : body.truncate(75, omission: "…", separator: " "),
      }
    end
  end
end
