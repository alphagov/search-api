module Indexer
  class CompareEnumerator < Enumerator
    NO_VALUE = :__no_value_found__
    BATCH_SIZE = 50
    DEFAULT_QUERY = { match_all: {} }
    DEFAULT_SORT = [{ _id: { order: 'asc' }}, { _type: { order: 'asc' }}]

    def initialize(left_index_name, right_index_name, search_body = {})
      super() do |yielder|
        left_enum = get_enum(left_index_name, search_body)
        right_enum = get_enum(right_index_name, search_body)
        left = right = nil
        loop do
          left  ||= get_next_from_enumerator(left_enum)
          right ||= get_next_from_enumerator(right_enum)

          break if left.nil? && right.nil?

          case compare_key(left) <=> compare_key(right)
          when -1
            yielder << [left, NO_VALUE]
            left = nil
          when 1
            yielder << [NO_VALUE, right]
            right = nil
          when 0, nil
            # on the nil case we are expect one of left or right to be nil
            # this means we have finished getting data form one of the enum
            # objects. We should continue to loop until both enums are finished.
            yielder << [left || NO_VALUE, right || NO_VALUE]
            left = right = nil
          end
        end
      end
    end

    def get_enum(index_name, search_body = {})
      documents = {}

      search_body[:query] ||= DEFAULT_QUERY
      search_body[:sort] ||= DEFAULT_SORT

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
      end
    end

  private

    def get_next_from_enumerator(enum)
      enum.next
    rescue StopIteration # we rescue this as we want both enumerators to complete
      nil
    end

    def compare_key(data)
      return nil if data.nil?
      [data['_root_id'], data['_root_type']]
    end

    def client
      Services.elasticsearch(
        hosts: search_config.elasticsearch["base_uri"],
        timeout: 30.0
      )
    end

    def search_config
      @search_config ||= SearchConfig.new
    end
  end
end
