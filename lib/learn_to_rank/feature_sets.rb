require "learn_to_rank/features"

module LearnToRank
  class FeatureSets
    # FeatureSets changes search results into hashes with features as
    # key values for processing by the LTR model.
    def call(query, search_results)
      search_results.map do |res|
        LearnToRank::Features.new(
          explain: res.fetch("_explanation", {}),
          popularity: res.dig("_source", "popularity"),
          es_score: res.fetch("_score", 0),
          title: res.dig("_source", "title"),
          description: res.dig("_source", "description"),
          link: res.dig("_source", "link"),
          public_timestamp: res.dig("_source", "public_timestamp"),
          format: res.dig("_source", "format"),
          organisation_content_ids: res.dig("_source", "organisation_content_ids"),
          query:,
          updated_at: res.dig("_source", "updated_at"),
          indexable_content: res.dig("_source", "indexable_content"),
        ).as_hash
      end
    end
  end
end
