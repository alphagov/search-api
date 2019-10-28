require "learn_to_rank/feature_sets"
require "learn_to_rank/ranker"

module LearnToRank
  class Reranker
    # Reranker re-orders elasticsearch results using a pre-trained model
    def rerank(es_results: [], count: DEFAULT_COUNT)
      feature_sets = FeatureSets.new.call(es_results)
      new_scores   = Ranker.new(feature_sets).ranks

      reorder_results(es_results, new_scores)
    end

  private

    DEFAULT_COUNT = 20
    MAX_MODEL_BOOST = 5

    def reorder_results(search_results, new_scores)
      search_results
        .map
        .with_index { |result, index|
          m_score = [new_scores[index], MAX_MODEL_BOOST].min
          es_score = result.fetch("_score", 0)
          result.merge(
            "model_score" => m_score,
            "original_rank" => index + 1,
            "combined_score" => m_score * es_score,
          )
        }
        .sort_by { |res| res["combined_score"] }
        .reverse
    end
  end
end
