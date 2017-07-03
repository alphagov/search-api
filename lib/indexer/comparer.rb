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

    def initialize(old_index_name, new_index_name, rejected_fields: DEFAULT_FIELDS_TO_IGNORE, max_keys_to_report: 100)
      @old_index_name = old_index_name
      @new_index_name = new_index_name
      @rejected_fields = rejected_fields
      @max_keys_to_report = max_keys_to_report
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
        document.clone.merge('_source' => consistent_hash(reject_fields(document['_source'])))
      end.each do |d|
        key = [d['_id'], d['_type']]
        documents[key] = d
      end

      log "Finished loading index: #{index_name}"

      documents
    end

    def reject_fields(hash)
      hash.reject{ |k, _| @rejected_fields.include?(k) }
    end

    def consistent_hash(hash)
      # sort the object as reasonible then convert to a string and final hash teh result
      # this allow us to check if to objects match with needing to store the full object
      hash_str = consistentify(hash).inspect
      Digest::SHA1.hexdigest(hash_str)
    end

    def consistentify(obj)
      case obj
      when Hash
        obj.to_a.sort_by(&:first).map { |a, b| [a, consistentify(b)]}
      when Array
        obj.map { |a| consistentify(a) }.sort_by(&:inspect)
      else
        obj
      end
    end

    def run
      outcomes = Hash.new { |h, k| h[k] = 0 }
      outcomes[:changed_key] = []

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
              outcomes[:changed_key] << key if outcomes[:changed_key].count < @max_keys_to_report
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
