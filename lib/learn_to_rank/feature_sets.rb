require "learn_to_rank/features"

module LearnToRank
  class FeatureSets
    # FeatureSets changes search results into hashes with features as
    # key values for processing by the LTR model.
    def call(search_results)
      search_results.map do |res|
        LearnToRank::Features.new(
          explain: res.fetch("_explanation", {}),
          popularity: res.dig("_source", "popularity"),
          es_score: res.fetch("_score", 0),
        ).as_hash
      end
    end
  end
end
