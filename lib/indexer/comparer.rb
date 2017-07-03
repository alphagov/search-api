# require_relative 'app';
# require 'pry'
# Indexer::Comparer.new(
#   'government',
#   'government-old-2017-06-21t11:04:56z-00000000-0000-0000-0000-000000000000',
#   'government-2017-06-21t11:55:51z-00000000-0000-0000-0000-000000000000'
# ).run

module Indexer
  class Comparer
    DEFAULT_FIELDS_TO_IGNORE = ["popularity"]
    BATCH_SIZE = 50

    def initialize(base_name, old_index_name, new_index_name, rejected_fields = DEFAULT_FIELDS_TO_IGNORE)
      @base_name = base_name
      @old_index_name = old_index_name
      @new_index_name = new_index_name
      @rejected_fields = rejected_fields
    end

    def log(msg)
      puts "#{Time.now}: #{msg}"
    end

    def client
      Services.elasticsearch(
        hosts: search_config.elasticsearch["base_uri"],
        timeout: 30.0
      )
    end

    def read_index(index_name, filter = nil)
      log "Access index: #{index_name}"

      documents = {}

      search_body = filter || { query: { match_all: {} } }

      log "Starting to load index: #{index_name} - #{search_body.inspect}"

      ScrollEnumerator.new(
        client: client,
        index_names: index_name,
        search_body: search_body,
        batch_size: BATCH_SIZE
      ) do |document|
        result = document['_source']
        root_elements = document.each_with_object({}) do |(k, v), h|
          h["_root#{k}"] = v unless k == '_source'
        end
        result.merge(root_elements)
      end.each do |d|
        key = [d['_root_id'], d['_root_type']]
        documents[key] = d
      end

      log "Finished loading index: #{index_name}"

      documents
    end

    def reject_fields(hash)
      hash.reject{ |k, _| @rejected_fields.include?(k) }
    end

    def run
      outcomes = Hash.new { |h, k| h[k] = 0 }

      filters.each do |filter|
        old_data = read_index(@old_index_name, filter)
        new_data = read_index(@new_index_name, filter)

        removed_keys = old_data.keys - new_data.keys
        outcomes[:removed_items] = removed_keys.count

        new_data.each do |key, new_item|
          old_item = old_data[key]

          if old_item.nil?
            outcomes[:added_items] += 1
          else
            fields = changed_fields(old_item, new_item)
            if fields.any?
              outcomes[:changed] += 1
              outcomes[:"changes: #{fields.join(',')}"] += 1
            else
              outcomes[:unchanged] += 1
            end
          end
        end
      end

      outcomes
    end

    # break the index down into managable chunks to reduce memory overhead
    def filters
      results = search_config.run_search('aggregate_format' => ['1000'], 'count' => ['0'])

      results[:aggregates]['format'][:options].map do |option|
        { query: { term: { format: option[:value]["slug"] } } }
      end
    end

    def search_config
      @search_config ||= SearchConfig.new
    end

    def changed_fields(old_item, new_item)
      return [] if reject_fields(old_item) == reject_fields(new_item)

      keys = (old_item.keys | new_item.keys) - @rejected_fields
      keys.select { |key| old_item[key] != new_item[key] }.sort
    end
  end
end
