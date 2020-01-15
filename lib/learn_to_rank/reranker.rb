require "learn_to_rank/feature_sets"
require "learn_to_rank/ranker"

# autoloading would be nice here
require "search/escaping"
require "search/query_components/base_component"
require "search/query_components/best_bets"

module LearnToRank
  class Reranker
    # Reranker re-orders elasticsearch results using a pre-trained model
    def rerank(query: "", es_results: [])
      feature_sets = FeatureSets.new.call(query, es_results)
      new_scores   = Ranker.new(feature_sets).ranks

      return nil if new_scores.nil?

      log_reranking

      reorder_results(es_results, new_scores)
    rescue StandardError => e
      GovukError.notify(e, extra: { query: query })
    end

  private

    MAX_MODEL_SCORE = QueryComponents::BestBets::MIN_BEST_BET_SCORE - 1

    def reorder_results(search_results, new_scores)
      ranked = search_results
        .map
        .with_index { |result, index|
          m_score = [new_scores[index], MAX_MODEL_SCORE].min
          es_score = result.fetch("_score", 0)
          result.merge(
            "model_score" => m_score,
            "original_rank" => index + 1,
            # keep best bet scores
            "combined_score" => es_score > MAX_MODEL_SCORE ? es_score : m_score,
          )
        }

      ranked.sort_by { |res| -res["combined_score"] }
    end

    def log_reranking
      GovukStatsd.increment "results_reranked"
    end
  end
end
