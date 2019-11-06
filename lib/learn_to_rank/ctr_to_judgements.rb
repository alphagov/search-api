module LearnToRank
  class CtrToJudgements
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
    def initialize(ctrs)
      @ctrs = ctrs.reduce({}, :merge)
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

    attr_reader :ctrs

    def ctr_to_relevancy_score(query_ctrs)
      benchmark = 0.0
      normalised_scores = Array.new

      # Calculate normalised scores and upper limit for benchmark
      query_ctrs.each_with_object({}) do |(position, ctr)|
        pos = Float(position)
        ctr = Float(ctr)

        # Generate a normalised score based on CTR
        k = (2 * (Math.log(pos + 1) + 1) * ctr ** 0.5) / 5
        normalised_scores.insert(position.to_i, k)
        if k > benchmark
          # Sets a new "high point" for searches and places it at top
          benchmark = k
          next
        end
      end

      query_ctrs.each_with_object({}) do |(position, ctr), h|
        pos = Float(position)
        ctr = Float(ctr)

        # Calculates relevancy score based on percentage of relevance to the
        # benchmark. Allows fine tuning of boundaries and takes into account
        # weak searches. Risks flattening the results if CTR calculation results
        # are close.
        known_ctr = normalised_scores[position.to_i]
        h[position.to_i] = if known_ctr < (benchmark / 100.0) * 0.5
          0
        elsif known_ctr < (benchmark / 100.0) * 5
          1
        elsif known_ctr < (benchmark / 100.0) * 80
          2
        else
          3
        end
      end
    end

    def fetch_results(query)
      q = query.gsub("_", "%20")
      url = "https://www.gov.uk/api/search.json?fields=link&q=#{q}"
      response = HTTParty.get(url)
      JSON.parse(response.body)
    end

    def scores_to_results(query, scores)
      results = fetch_results(query).fetch('results')
      scores.map do |(position, score)|
        next unless results[position.to_i]
        {
          query: query,
          score: score,
          link: results[position.to_i].dig('link')
        }
      end
    end
  end
end
