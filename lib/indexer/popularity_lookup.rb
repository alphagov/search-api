module Indexer
  class PopularityLookup
    def initialize(index_name, search_config)
      @index_name = index_name
      @search_config = search_config
    end

    def lookup_popularities(links)
      if traffic_index.nil?
        return {}
      end

      response = traffic_index.raw_search({
        query: {
          terms: {
            path_components: links,
          },
        },
        _source: { includes: %w[rank_14 vc_14] },
        sort: [
          { rank_14: { order: "asc" } },
        ],
        size: 10 * links.size,
      })

      default_rank = Hash.new({
        rank: traffic_index_size,
        view_count: 1,
      })

      ranks = EsExtract::Hits.array(response).each_with_object(default_rank) do |hit, hsh|

        rank = Array(EsExtract::Hits.source(hit, "rank_14")).first
        next if rank.nil?

        link = EsExtract::Hits.id(hit)
        view_count = EsExtract::Hits.source(hit, "vc_14") || 1
        hsh[link] = { rank:, view_count: }
      end


      #
      #
      #  next if rank.nil?

      #
      #  view_count = EsExtract::Hits.source(hit, "vc_14") || 1
      #  hsh[link] = { rank:, view_count: }
      #end

      Hash[links.map do |link|
        if ranks[link][:rank].zero?
          popularity_score = 0
          popularity_rank = 1
        else
          popularity_score = 1.0 / (ranks[link][:rank] + SearchConfig.popularity_rank_offset)
          popularity_rank = traffic_index_size - (ranks[link][:rank] || traffic_index_size)
        end

        view_count = ranks[link][:view_count]

        [
          link,
          {
            popularity_score:,
            popularity_rank:,
            view_count:,
          },
        ]
      end]
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
      @traffic_index_size ||= begin
        response = traffic_index.raw_search({
          query: { match_all: {} },
          size: 0,
        })
        EsExtract::Hits.total(response)
      end
    end

    def open_traffic_index
      if @index_name.start_with?("page-traffic")
        return nil
      end

      traffic_index_name = SearchConfig.auxiliary_index_names.find do |index|
        index.start_with?("page-traffic")
      end

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
