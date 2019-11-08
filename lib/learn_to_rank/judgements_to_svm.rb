module LearnToRank
  class JudgementsToSvm
    # JudgementsToSvm translates judgements to SVM format
    # IN: [{ query: "tax", rank: 2, features: { "1": 2, "2": 0.1 } }]
    # OUT: "2 qid:4 1:2 2:0.1"
    def initialize(judgements = [])
      @judgements = judgements
      @features = get_feature_keys(judgements)
      @queries = get_query_ids(judgements)
    end

    def svm_format
      judgements.map { |j| judgement_to_svm(j) }
    end

  private

    attr_reader :judgements, :queries, :features

    def judgement_to_svm(judgement)
      rank = (judgement[:rank]).to_s
      query_id = "qid:#{queries[judgement[:query]]}"
      feats = features.map { |feat| "#{feat}:#{judgement.dig(:features, feat) || 0}" }
      [rank, query_id, feats].flatten.compact.join(" ")
    end

    def get_query_ids(judgements)
      latest = 0
      judgements.each_with_object({}) do |judgement, hsh|
        next if hsh[judgement[:query]]

        hsh[judgement[:query]] = (latest += 1)
      end
    end

    def get_feature_keys(judgements)
      return [] unless judgements.any?

      judgements.first[:features].keys.sort
    end
  end
end
