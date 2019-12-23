module LearnToRank
  class RelevancyJudgements
    # RelevancyJudgements takes hash of queries and the top documents returned,
    # with the doc content_id, view counts, click counts, and avg rank.
    # and turns them into normalised relevancy judgements between 0 and 3.
    # INPUT: {
    #   "my query" => [
    #       {
    #         content_id: '0f131434-cc04-4400-b418-ed6f81a09127',
    #         rank:   2,
    #         views:  5000,
    #         clicks: 2500,
    #       },
    #       ...
    #     ]
    #   }
    # }
    # OUTPUT [{ query: 'my query', score: 3, content_id: '0f131434-cc04-4400-b418-ed6f81a09127' }]

    attr_reader :relevancy_judgements

    def initialize(queries:)
      @relevancy_judgements = judgement_sets(queries).flatten
    end

  private

    def judgement_sets(queries)
      queries.map do |(query, documents)|
        judgements(query, documents)
      end
    end

    # Turn a set of view and click counts for documents in search
    # results into estimated click-through-rate@1 and then into
    # a set of judgements between 0 and 3.
    def judgements(query, documents)
      clicks_above_position = 0
      ranked_documents = documents.sort_by { |doc| doc[:rank] }
      ranked_documents.map do |document|
        views = Float(document[:views]) - clicks_above_position
        clicks = Float(document[:clicks])
        views = clicks unless views >= clicks
        # predicted ctr@1 to handle positional bias
        clicks_above_position += clicks
        relevancy_score = if views > 3
                            ctr_to_relevancy_score((clicks / views) * 100.0)
                          else
                            1 # bad but don't know if it's terrible
                          end

        {
          query: query,
          score: relevancy_score,
          link: document[:link],
        }
      end
    end

    # Turn an estimated click-through-rate@1 into an estimated score
    # between 0 and 3
    # TODO: These are quite arbitrary, based on what we think a good
    # CTR at position 1 would be.
    def ctr_to_relevancy_score(ctr)
      case ctr
      when 20..1000 then 3
      when 10..20 then 2
      when 2..10 then 1
      else
        0
      end
    end
  end
end
