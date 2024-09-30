module GovukIndex
  class PopularityWorker < Indexer::BaseWorker
    BULK_INDEX_TIMEOUT = 60
    QUEUE_NAME = "bulk".freeze
    sidekiq_options queue: QUEUE_NAME

    def perform(record_ids, source_index_name, destination_index_name)
      actions = Index::ElasticsearchProcessor.new(client: GovukIndex::Client.new(timeout: BULK_INDEX_TIMEOUT, index_name: destination_index_name))

      source_index = IndexFinder.by_name(source_index_name)

      popularities = retrieve_popularities_for(destination_index_name, record_ids)
      record_ids.each do |record_id|
        document = source_index.get_document_by_id(record_id)

        unless document
          puts "Skipping #{record_id} as it is not in the index"
          next
        end

        actions.save(
          process_record(document, popularities),
        )
      end

      actions.commit
    end

    def process_record(document, popularities)
      base_path = document.fetch("_id")
      title = document.fetch("title")
      identifier = document.slice("_id", "_version")
      OpenStruct.new(
        identifier: identifier.merge("version_type" => "external_gte", "_type" => "generic-document"),
        document: document.fetch("_source").merge(
          "popularity" => popularities.dig(base_path, :popularity_score),
          "popularity_b" => popularities.dig(base_path, :popularity_rank),
          "view_count" => popularities.dig(base_path, :view_count),
          "autocomplete" => { # Relies on updated popularity. Title is for new records.
            "input" => document["_source"]["title"],
            "weight" => popularities.dig(base_path, :popularity_rank),
          },
        ),
      )
    end

    def retrieve_popularities_for(index_name, record_ids)
      # popularity should be consistent across clusters, so look up in
      # the default
      lookup = Indexer::PopularityLookup.new(index_name, SearchConfig.default_instance)
      lookup.lookup_popularities(record_ids)
    end
  end
end
