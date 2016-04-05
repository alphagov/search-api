require_relative "../../app"
require 'indexer/links_lookup'

module Indexer
  class IndexDocuments
    NON_MIGRATED_APPS = %w(
      publisher
      service-manual-publisher
      specialist-publisher
      whitehall
      non-migrated-app
    ).freeze

    EXCLUDED_FORMATS = %{
      email_alert_signup
      gone
      redirect
    }

    def process(message)
      with_logging(message) do
        index_links_from_message(message.payload)
        message.ack
      end
    rescue GdsApi::HTTPServerError => e
      $stderr.puts "An error occurred!"
      $stderr.puts e.inspect
      message.retry
    rescue ProcessingError => e
      Airbrake.notify_or_ignore(e, parameters: message.payload)
      message.discard
    rescue StandardError => e
      $stderr.puts "Unknown Exception: #{e.message}"
      Airbrake.notify_or_ignore(e, parameters: message.payload)
      sleep 1
      message.retry
    end

  private

    def with_logging(message)
      log_payload = message.payload.slice(*%w[
        content_id
        base_path
        document_type
        title
        update_type
        publishing_app
      ])

      puts "Processing message [#{message.delivery_info.delivery_tag}]: #{log_payload.to_json}"

      yield

      puts "Finished processing message [#{message.delivery_info.delivery_tag}]"
    end

    def index_links_from_message(payload)
      return if should_skip_document?(payload)

      base_path = payload.fetch("base_path")
      document = get_document_for_base_path(base_path)

      raw_links = payload.fetch("links", {})
      links = Indexer::LinksLookup.new.rummager_fields_from_links(raw_links)

      update_document_in_search_index(document, links)
    rescue KeyError => e
      raise MalformedMessage, "Content item attribute missing. #{e.message}"
    end

    def update_document_in_search_index(document, links)
      index = search_server.index(document['real_index_name'])
      index.amend(document['_id'], links)
    end

    def should_skip_document?(content_item)
      NON_MIGRATED_APPS.include?(content_item.fetch("publishing_app")) ||
        EXCLUDED_FORMATS.include?(content_item.fetch("document_type"))
    end

    def get_document_for_base_path(document_base_path)
      unified_index = search_server.index_for_search(search_config.content_index_names)
      document = unified_index.get_document_by_link(document_base_path)
      document || raise(UnknownDocumentError, "Document not found in index")
    end

    def search_server
      @search_server ||= search_config.search_server
    end

    def search_config
      @search_config ||= Rummager.settings.search_config
    end

    class ProcessingError < StandardError
    end

    class UnknownDocumentError < ProcessingError
    end

    class MalformedMessage < ProcessingError
    end
  end
end
