require "learn_to_rank/feature_sets"
require "learn_to_rank/ranker"

module LearnToRank
  class Reranker
    # Reranker re-orders elasticsearch results using a pre-trained model
    def rerank(query: "", es_results: [])
      feature_sets = FeatureSets.new.call(query, es_results)
      new_scores   = Ranker.new(feature_sets).ranks

      log_reranking

      reorder_results(es_results, new_scores)
    end

  private

    MAX_MODEL_BOOST = 5

    def reorder_results(search_results, new_scores)
      ranked = search_results
        .map
        .with_index { |result, index|
          m_score = [new_scores[index], MAX_MODEL_BOOST].min
          es_score = result.fetch("_score", 0)
          result.merge(
            "model_score" => m_score,
            "original_rank" => index + 1,
            # keep best bet scores
            "combined_score" => es_score > 1000 ? es_score : m_score,
          )
        }

      ranked.sort_by { |res| -res["combined_score"] }
    end

    def log_reranking
      GovukStatsd.increment "results_reranked"
    end
  end
end
