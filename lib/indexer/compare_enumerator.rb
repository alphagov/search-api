module Indexer
  class CompareEnumerator < Enumerator
    NO_VALUE = :__no_value_found__
    BATCH_SIZE = 250
    DEFAULT_QUERY = { match_all: {} }.freeze
    # sort by the document_type then the _uid, which is "type#id" -
    # sorting on the id directly is not possible, and the type will
    # always be "generic-document", which is why we first need to sort
    # by document_type.
    DEFAULT_SORT = %i(document_type _uid).freeze

    def initialize(left_index_name, right_index_name, cluster = Clusters.default_cluster, search_body = {}, options = {})
      @cluster = cluster
      @options = options
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
            # on the nil case we are expecting one of left or right to be nil
            # this means we have finished getting data form one of the enum
            # objects. We should continue to loop until both enums are finished.
            yielder << [left || NO_VALUE, right || NO_VALUE]
            left = right = nil
          end
        end
      end
    end

    def get_enum(index_name, search_body = {})
      search_body[:query] ||= DEFAULT_QUERY
      search_body[:sort] ||= DEFAULT_SORT

      ScrollEnumerator.new(
        client: client,
        index_names: index_name,
        search_body: search_body,
        batch_size: BATCH_SIZE
      ) do |document|
        flattened_document(document)
      end
    end

    def flattened_document(document)
      result = {
        "_root_id" => document["_id"],
        "_root_type" => document["_source"]["document_type"],
      }

      result["_root_version"] = document["_version"] if @options[:include_version]
      result.merge(document['_source'])
    end

  private

    attr_reader :cluster

    def get_next_from_enumerator(enum)
      enum.next
    rescue StopIteration # we rescue this as we want both enumerators to complete
      nil
    end

    def compare_key(data)
      return nil if data.nil?
      [data['_root_type'], data['_root_id']]
    end

    def client
      Services.elasticsearch(cluster: cluster, timeout: 30.0)
    end

    def search_config
      @search_config ||= SearchConfig.instance(cluster)
    end
  end
end
