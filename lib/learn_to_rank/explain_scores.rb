module LearnToRank
  class ExplainScores
    # Given an explanation for a document, returns a hash of the total scores
    # e.g. { title_score: 0.2, description_score: 0.2, ... }
    # attr_reader :title_score, :description_score, :all_searchable_text_score, :indexable_content_score

    PERMITTED_FIELDS = [:title_score, :description_score, :all_searchable_text_score, :indexable_content_score]

    def initialize(explain)
      scores = scores_from_explain(explain)
      PERMITTED_FIELDS.each do |field|
        define_singleton_method field do
          scores[field] || 0
        end
      end
    end

  private

    attr_reader :scores

    def field_permitted?(field)
      PERMITTED_FIELDS.include? field
    end

    def scores_from_explain(explain)
      description = explain.fetch("description", "")
      if description.include? "PerFieldSimilarity"
        # is a bm25 score so return that value
        field = (description.split("(")[1].split(":")[0].split(".")[0] + "_score").downcase.to_sym
        return {} unless field_permitted? field

        value = explain["value"]
        { field => value }
      elsif ["sum of:", "max of:", "function score, product of:"].include? description
        # is not a bm25 score so return the sum of scores contained within
        default_hash = Hash.new(0)
        explain["details"].each_with_object(default_hash) do |sub_explain, hsh|
          scores = scores_from_explain(sub_explain)
          scores.keys.each do |key|
            hsh[key] += scores[key]
          end
        end
      else
        # Is not bm25 score, and doesn't contain any
        {}
      end
    end
  end
end
