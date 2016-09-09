require "legacy_search/advanced_search_query_builder"

module LegacySearch
  class InvalidQuery < ArgumentError
  end

  class AdvancedSearch
    def initialize(mappings, document_types, client, index_name)
      @mappings = mappings
      @document_types = document_types
      @client = client
      @index_name = index_name
    end

    def result_set(params)
      logger.info "params:#{params.inspect}"
      if params["per_page"].nil? || params["page"].nil?
        raise LegacySearch::InvalidQuery, "Pagination params are required."
      end

      # Delete params that we don't want to be passed as filter_params
      order     = params.delete("order")
      keywords  = params.delete("keywords")
      per_page  = params.delete("per_page").to_i
      page      = params.delete("page").to_i

      query_builder = AdvancedSearchQueryBuilder.new(keywords, params, order, @mappings)

      unless query_builder.valid?
        raise LegacySearch::InvalidQuery, query_builder.error
      end

      starting_index = page <= 1 ? 0 : (per_page * (page - 1))
      payload = {
        "from" => starting_index,
        "size" => per_page
      }

      payload.merge!(query_builder.query_hash)

      Search::ResultSet.from_elasticsearch(@document_types, raw_search(payload))
    end

  private

    def raw_search(payload)
      @client.search(index: @index_name, body: payload)
    end

    def logger
      Logging.logger[self]
    end
  end
end
