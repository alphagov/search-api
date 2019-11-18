require "learn_to_rank/explain_scores"

module LearnToRank
  class Features
    # Features takes some values and translates them to features
    def initialize(explain: {}, popularity: 0, es_score: 0)
      @popularity = popularity
      @es_score = es_score
      @explain_scores = LearnToRank::ExplainScores.new(explain)
    end

    def as_hash
      {
        "1" => Float(@popularity),
        "2" => Float(@es_score),
        "3" => Float(explain_scores.title_score || 0),
        "4" => Float(explain_scores.description_score || 0),
        "5" => Float(explain_scores.indexable_content_score || 0),
        "6" => Float(explain_scores.all_searchable_text_score || 0),
      }
    end

  private

    attr_reader :explain_scores, :es_score, :popularity
  end
end
