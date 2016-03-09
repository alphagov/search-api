require_relative "../../app"
require 'indexer/links_lookup'

module Indexer
  class IndexDocuments
    MIGRATED_TAGGING_APPS = %w{
      businesssupportfinder
      calculators
      calendars
      collections-publisher
      contacts
      contacts-admin
      hmrc-manuals-api
      licencefinder
      policy-publisher
      smartanswers
    }

    def process(message)
      $stdout.puts "Processing message: #{message.payload.inspect}"
      index_links_from_message(message)
      message.ack
    rescue GdsApi::HTTPServerError => e
      $stderr.puts "An error occurred!"
      $stderr.puts e.inspect
      message.retry
    rescue ProcessingError => e
      Airbrake.notify_or_ignore(e, parameters: message.payload)
      message.discard
    end

  private

    def index_links_from_message(message)
      return unless publishing_app_migrated?(message)

      base_path = message.payload.fetch("base_path")
      document = get_document_for_base_path(base_path)

      raw_links = links_from_payload(message)
      links = Indexer::LinksLookup.new.rummager_fields_from_links(raw_links)

      index = search_server.index(document['real_index_name'])
      index.amend(document['_id'], links)
    end

    def publishing_app_migrated?(message)
      MIGRATED_TAGGING_APPS.include? message.payload["publishing_app"]
    end

    def links_from_payload(message)
      message.payload.fetch("links", {})
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
  end
end
