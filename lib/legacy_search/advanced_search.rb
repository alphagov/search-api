module LegacySearch
  class InvalidQuery < ArgumentError
  end

  class AdvancedSearch
    def initialize(mappings, elasticsearch_types, client, index_name)
      @mappings = mappings
      @elasticsearch_types = elasticsearch_types
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

      if page > 500_000
        raise LegacySearch::InvalidQuery, "The maximum for `page` parameter is 500000."
      end

      query_builder = AdvancedSearchQueryBuilder.new(keywords, params, order, @mappings)

      unless query_builder.valid?
        raise LegacySearch::InvalidQuery, query_builder.error
      end

      starting_index = page <= 1 ? 0 : (per_page * (page - 1))
      payload = {
        "from" => starting_index,
        "size" => per_page
      }

      if page > 250
        # we need to use the scroll API
        batch_size = per_page * 15
        batch_page = starting_index / batch_size - 1
        data = ScrollEnumerator.new(
          client: @client,
          index_names: @index_name,
          search_body: query_builder.query_hash,
          batch_size: batch_size,
          process_in_batch: true
        )
        batch_page.times { data.next }

        batch_results = data.next
        start_pos = (starting_index % batch_size)
        end_pos = (starting_index % batch_size + per_page - 1)
        puts "page: #{page}, per_page: #{per_page}"
        puts "start_index: #{starting_index}, batch_size: #{batch_size}, batch_page: #{batch_page}, start_pos: #{start_pos}, end_pos: #{end_pos}"
        results = batch_results[start_pos..end_pos]

        Search::ResultSet.from_elasticsearch(@elasticsearch_types, 'hits' => { 'total' => data.size, 'hits' => results})
      else
        payload.merge!(query_builder.query_hash)

        Search::ResultSet.from_elasticsearch(@elasticsearch_types, raw_search(payload))
      end
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
