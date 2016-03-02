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
    end

  private

    def index_links_from_message(message)
      return unless publishing_app_migrated?(message)
      raw_links = links_from_payload(message)

      links = Indexer::LinksLookup.new.rummager_fields_from_links(raw_links)
      base_path = document_base_path(message)
      update_index(base_path, links)
    end

    def publishing_app_migrated?(message)
      MIGRATED_TAGGING_APPS.include? message.payload["publishing_app"]
    end

    def links_from_payload(message)
      message.payload.fetch("links", {})
    end

    def document_base_path(message)
      message.payload.fetch("base_path")
    end

    def update_index(base_path, links)
      indices_with_base_path(base_path).map do |index|
        index.amend(base_path, links)
      end
    end

    def indices_with_base_path(document_base_path)
      indices_to_search = search_server.index_for_search(search_config.content_index_names)
      results = indices_to_search.raw_search(query: { term: { link: document_base_path } })

      results["hits"]["hits"].map do |hit|
        index = SearchIndices::Index.strip_alias_from_index_name(hit["_index"])
        search_server.index(index) if index
      end
    end

    def search_server
      @search_server ||= search_config.search_server
    end

    def search_config
      @search_config ||= Rummager.settings.search_config
    end
  end
end
