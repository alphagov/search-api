module LearnToRank::DataPipeline
  class JudgementsToSvm
    # JudgementsToSvm translates judgements to SVM format
    # IN: enumerator of { query: "tax", score: 2, features: { "1": 2, "2": 0.1 } }
    # OUT: lazy enumerator of "2 qid:4 1:2 2:0.1"
    def initialize(judgements = [])
      @judgements = judgements
    end

    def svm_format_grouped_by_query
      svm_format.chunk { |row| row.split(" ")[1] }.map { |chunk| chunk[1] }
    end

    def svm_format
      latest = 0
      query_ids = {}
      features = nil

      judgements.lazy.map do |j|
        if features.nil?
          features = j[:features].keys.sort
        end

        query_id = query_ids[j[:query]]
        if query_id.nil?
          latest += 1
          query_id = latest
          query_ids[j[:query]] = latest
        end

        judgement_to_svm(query_id, j, features)
      end
    end

  private

    attr_reader :judgements

    def judgement_to_svm(query_id, judgement, features)
      score = (judgement[:score]).to_s
      qid = "qid:#{query_id}"
      feats = features.map { |feat| "#{feat}:#{judgement.dig(:features, feat) || 0}" }
      [score, qid, feats].flatten.compact.join(" ")
    end
  end
end
