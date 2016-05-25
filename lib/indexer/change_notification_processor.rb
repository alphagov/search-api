# ChangeNotificationProcessor
#
# This is called by the message queue processor and is responsible
# for acting on the incoming payload. It checks if the updated document in the
# payload needs to be updated, looks up the document in elasticsearch and triggers
# a "re-index", which means that the document will go through the DocumentPreparer
# process and will look up the tags for the document again.
module Indexer
  class ChangeNotificationProcessor
    EXCLUDED_FORMATS = %w{email_alert_signup gone redirect}.freeze

    # Gets initialised with a content-item from the publishing-api message queue.
    def initialize(content_item)
      @content_item = content_item
    end

    def trigger
      return if should_skip_document?
      trigger_indexing_of_document
    rescue KeyError => e
      raise Indexer::MalformedMessage, "Content item attribute missing. #{e.message}"
    end

  private

    attr_reader :content_item

    def document
      @document ||= begin
        document_base_path = content_item.fetch("base_path")
        index = IndexFinder.content_index
        document = index.get_document_by_link(document_base_path)
        document || raise(Indexer::UnknownDocumentError, "Document not found in index")
      end
    end

    def trigger_indexing_of_document
      index = IndexFinder.by_name(document['real_index_name'])
      index.trigger_document_reindex(document['_id'])
    end

    def should_skip_document?
      EXCLUDED_FORMATS.include?(content_item.fetch("document_type"))
    end
  end
end
