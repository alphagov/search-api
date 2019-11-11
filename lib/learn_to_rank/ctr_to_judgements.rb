module LearnToRank
  class CtrToJudgements
    PUBLIC_SEARCH_API = "https://www.gov.uk/api/search.json".freeze

    # CtrToJudgements takes an array of query:position click-through-rates
    # and turns them into normalised relevancy judgements between 0 and 3.
    # INPUT [{
    #   "my query" => {
    #     "1": 10,
    #     "2": 23,
    #     "3": 40,
    #     "4": 5,
    #   }
    # }]
    # OUTPUT [{ query: 'my query', score: 3, link: '/the-best-result' }]
    def initialize(ctrs, search_api: PUBLIC_SEARCH_API)
      @ctrs = ctrs.reduce({}, :merge)
      @search_api = search_api
    end

    def relevancy_judgements
      ctrs.map { |(query, query_ctrs)|
        sleep 0.1
        scores_to_results(query, ctr_to_relevancy_score(query_ctrs))
      }
        .flatten
        .compact
    end

  private

    attr_reader :ctrs, :search_api

    def ctr_to_relevancy_score(query_ctrs)
      query_ctrs.each_with_object({}) do |(position, ctr), h|
        pos = Float(position)
        ctr = Float(ctr)
        k = (2 * (Math.log(pos + 1) + 1) * ctr**0.5) / 5
        h[position] = if k < 0.1
                        0
                      elsif k < 1
                        1
                      elsif k < 2
                        2
                      else
                        3
                      end
      end
    end

    def fetch_results(query)
      q = query.gsub("_", "%20")
      url = "#{search_api}?fields=link&q=#{q}"
      response = HTTParty.get(url)
      JSON.parse(response.body)
    end

    def scores_to_results(query, scores)
      results = fetch_results(query).fetch("results")
      scores.map do |(position, score)|
        next unless results[position.to_i]

        {
          query: query,
          score: score,
          link: results[position.to_i].dig("link"),
        }
      end
    end
  end
end
