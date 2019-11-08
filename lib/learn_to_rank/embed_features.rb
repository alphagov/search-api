require "learn_to_rank/features"

module LearnToRank
  class EmbedFeatures
    # EmbedFeatures takes a set of relevancy judgements and add features to them.
    # INPUT: [{ query: "a1", "id": "/universal-credit", rank: 1 }]
    # OUTPUT: [{ query: "a1", "id": "/universal-credit", rank: 1,
    #            view_count: 2, description_score: 2, title_score: 4 ... }]
    def initialize(judgements)
      @judgements = judgements
      @cached_queries = {}
    end

    def augmented_judgements
      count = Float(judgements.count)
      res = judgements.compact.map.with_index do |judgement, i|
        puts "#{i}/#{count}: #{(i/count)*100}%"
        feats = features(judgement)
        next nil unless feats
        judgement.merge(feats)
      end.compact
      flush_cached_queries
      res
    end

  private

    attr_reader :judgements

    def features(judgement)
      doc = fetch_document(judgement)
      return unless doc

      feats = LearnToRank::Features.new(
        explain: doc.fetch(:_explanation, {}),
        popularity: doc["popularity"],
        es_score: doc[:es_score],
      ).as_hash

      { features: feats }
    end

    def fetch_document(judgement)
      # TODO: Could we use MTerm Vectors API for this?
      begin
        retries ||= 0
        query = {
          "q" => [judgement[:query]],
          "debug" => %w(explain),
          "fields" => %w(popularity title),
          "count" => ["20"]
        }
        @cached_queries[judgement[:query]] ||= do_fetch(query)
        results = @cached_queries[judgement[:query]]
        if @cached_queries.keys.count > 50
          flush_cached_queries
        end
        results.find { |doc| doc[:_id] == judgement[:id] }
      rescue StandardError => e
        puts e
        sleep 5
        retry if (retries += 1) < 3
        nil
      end
    end

    def flush_cached_queries
      @cached_queries = {}
    end

    def do_fetch(query)
      sleep 0.2
      SearchConfig.run_search(query)[:results]
    end
  end
end
