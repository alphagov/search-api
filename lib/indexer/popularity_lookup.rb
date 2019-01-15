module Indexer
  class PopularityLookup
    def initialize(index_name, search_config)
      @index_name = index_name
      @search_config = search_config
    end

    def lookup_popularities(links)
      if traffic_index.nil?
        return nil
      end

      results = traffic_index.raw_search({
        query: {
          terms: {
            path_components: links
          }
        },
        _source: { includes: %w[rank_14] },
        sort: [
          { rank_14: { order: "asc" } }
        ],
        size: 10 * links.size,
      })

      ranks = Hash.new(traffic_index_size)

      results["hits"]["hits"].each do |hit|
        link = hit["_id"]
        rank = Array(hit["_source"]["rank_14"]).first
        next if rank.nil?
        ranks[link] = [rank, ranks[link]].min
      end

      Hash[links.map { |link|
        if ranks[link] == 0
          popularity_score = 0
        else
          popularity_score = 1.0 / (ranks[link] + @search_config.popularity_rank_offset)
        end

        [link, popularity_score]
      }]
    end

  private

    def traffic_index
      if @opened_traffic_index
        return @traffic_index
      end
      @traffic_index = open_traffic_index
      @opened_traffic_index = true
      @traffic_index
    end

    def traffic_index_size
      results = traffic_index.raw_search({
        query: { match_all: {} },
        size: 0
      })
      results["hits"]["total"]
    end

    def open_traffic_index
      if @index_name.start_with?("page-traffic")
        return nil
      end

      traffic_index_name = @search_config.auxiliary_index_names.find {|index|
        index.start_with?("page-traffic")
      }

      if traffic_index_name
        result = @search_config.search_server.index(traffic_index_name)

        if result.exists?
          return result
        end
      end

      nil
    end
  end
end
