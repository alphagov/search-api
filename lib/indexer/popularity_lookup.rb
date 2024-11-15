module Indexer
  class PopularityLookup
    attr_reader :traffic_index
    def initialize(index_name, traffic_index)
      @index_name = index_name
      @traffic_index = traffic_index
    end

    def lookup_popularities(links)
      if traffic_index.nil?
        return {}
      end

      results = traffic_index.raw_search({
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

      default_rank = Hash.new(
        rank: traffic_index_size,
        view_count: 1,
      )

      ranks = results["hits"]["hits"].each_with_object(default_rank) do |hit, hsh|
        link = hit["_id"]
        rank = Array(hit.dig("_source", "rank_14")).first
        view_count = hit.dig("_source", "vc_14") || 1
        next if rank.nil?

        hsh[link] = { rank:, view_count: }
      end

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

    def traffic_index_size
      @traffic_index_size ||= begin
        results = traffic_index.raw_search({
          query: { match_all: {} },
          size: 0,
        })
        results["hits"]["total"]
      end
    end
  end
end
