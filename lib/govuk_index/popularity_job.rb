module GovukIndex
  class PopularityJob < BaseJob
    BULK_INDEX_TIMEOUT = 60
    QUEUE_NAME = "bulk".freeze
    sidekiq_options queue: QUEUE_NAME

    def perform(document_ids, index_name)
      actions = Index::ElasticsearchProcessor.new(
        client: GovukIndex::Client.new(timeout: BULK_INDEX_TIMEOUT, index_name:),
      )
      index = IndexFinder.by_name(index_name)
      popularities = retrieve_popularities_for(index_name, document_ids)

      document_ids.each do |document_id|
        document = index.get_document_by_id(document_id)
        unless document
          logger.warn "Skipping #{document_id} as it is not in the index"
          next
        end

        actions.save(
          process_document(document, popularities),
        )
      end

      actions.commit
    end

    def process_document(document, popularities)
      base_path = document.fetch("_id")
      title = document.dig("_source", "title")
      identifier = document.slice("_id", "_version")
      OpenStruct.new(
        identifier: identifier.merge("version_type" => "external_gte", "_type" => "generic-document"),
        document: document.fetch("_source").merge(
          "popularity" => popularities.dig(base_path, :popularity_score),
          "popularity_b" => popularities.dig(base_path, :popularity_rank),
          "view_count" => popularities.dig(base_path, :view_count),
          "autocomplete" => { # Relies on updated popularity. Title is for new documents.
            "input" => title,
            "weight" => popularities.dig(base_path, :popularity_rank),
          },
        ),
      )
    end

  private

    def retrieve_popularities_for(index_name, document_ids)
      # popularity should be consistent across clusters, so look up in
      # the default
      lookup = Indexer::PopularityLookup.new(index_name, SearchConfig.default_instance.search_server.index(SearchConfig.page_traffic_index_name))
      lookup.lookup_popularities(document_ids)
    end
  end
end
