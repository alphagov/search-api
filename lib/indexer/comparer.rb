# require_relative 'app';
# require 'pry'
# Indexer::Comparer.new(
#   'government',
#   'government-old-2017-06-21t11:04:56z-00000000-0000-0000-0000-000000000000',
#   'government-2017-06-21t11:55:51z-00000000-0000-0000-0000-000000000000'
# ).run

module Indexer
  class Comparer
    # Source fields to ignore when comparing old and new objects for equality.
    # These are ones which we know have changed for most documents.
    FIELDS_TO_IGNORE = ["_id", "_type", "popularity"]

    def initialize(base_name, old_index_name, new_index_name)
      @base_name = base_name
      @old_index_name = old_index_name
      @new_index_name = new_index_name
    end

    def log(msg)
      puts "#{Time.now}: #{msg}"
    end

    def read_index(index_name, filter = nil)
      log "Access index: #{index_name}"
      index = search_config.search_server.index_group(@base_name).index_for_name(index_name)

      documents = {}


      search_body = filter || { query: { match_all: {} } }
      batch_size = index.class.scroll_batch_size

      log "Starting to load index: #{index_name} - #{search_body.inspect}"
      i = 0
      ScrollEnumerator.new(
        client: index.send(:build_client, timeout_options),
        index_names: index_name,
        search_body: search_body,
        batch_size: batch_size
      ) do |document|
        # it would be nice to flatten or tidy up this hash before it is returned
        # however everything I tried resulted in memory bloat. I am not 100% sure
        # why this was the case.
        result = document.delete('_source')
        result.merge!(
          '_root_id' => document['_id'],
          '_root_type' => document['_type'],
        )
        i += 1
        if i > 1000
          GC.start
          i = 0
        end
        result
      end.each do |d|
        key = [d['_id'], d['_type']]
        documents[key] = d
      end

      log "Finished loading index: #{index_name}"

      documents
    end

    def timeout_options
      {
        timeout: 30.0
      }
    end

    def reject_fields(hash)
      hash.reject{ |k, _| FIELDS_TO_IGNORE.include?(k) }
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

          outcomes[:inconsistent_id] += 1 if new_item['_id'] != new_item['_root_id']
          outcomes[:inconsistent_type] += 1 if new_item['_type'] != new_item['_root_type']
        end
      end

      outcomes
    end

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
      return [] if old_item == new_item

      keys = (old_item.keys | new_item.keys) - ['_source']
      changed_root_keys = keys.select { |key| old_item[key] != new_item[key] }

      keys = old_item['_source'].keys | new_item['_source'].keys
      changed_source_keys = keys.select { |key| old_item['_source'][key] != new_item['_source'][key] }.map {|a| "_source.#{a}"}

      (changed_root_keys + changed_source_keys).sort
    end
  end
end
