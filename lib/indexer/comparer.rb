module Indexer
  class Comparer
    class MissingIdOrType < StandardError; end

    DEFAULT_FIELDS_TO_IGNORE = %w[popularity].freeze

    def initialize(old_index_name, new_index_name, cluster: Clusters.default_cluster, filtered_format: nil, ignore: DEFAULT_FIELDS_TO_IGNORE, io: $stdout, field_comparer: nil, enum_options: {})
      @old_index_name = old_index_name
      @new_index_name = new_index_name
      @filtered_format = filtered_format
      @field_to_ignore = ignore
      @field_comparer = field_comparer || ->(_id, key, old, new) { key =~ /^_root/ || old == new }
      @io = io
      @cluster = cluster
      @enum_options = enum_options
    end

    def run
      outcomes = Hash.new(0)

      log "processing: #{@old_index_name}/#{@new_index_name}"

      search_body = {}
      if @filtered_format
        search_body[:post_filter] = { term: { format: @filtered_format } }
      end

      CompareEnumerator.new(@old_index_name, @new_index_name, @cluster, search_body, @enum_options).each do |old_item, new_item|
        if old_item == CompareEnumerator::NO_VALUE
          outcomes[:added_items] += 1
        elsif new_item == CompareEnumerator::NO_VALUE
          outcomes[:removed_items] += 1
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

      outcomes
    end

    def search_config
      @search_config ||= SearchConfig.default_instance
    end

    def changed_fields(old_item, new_item)
      return [] if reject_fields(old_item) == reject_fields(new_item)

      keys = (old_item.keys | new_item.keys) - @field_to_ignore
      keys.reject { |key| @field_comparer.call(old_item["_root_id"], key, old_item[key], new_item[key]) }.sort
    end

    def reject_fields(hash)
      hash.reject { |k, _| @field_to_ignore.include?(k) }
    end

    def log(msg)
      @io.puts "#{Time.now}: #{msg}"
    end
  end
end
