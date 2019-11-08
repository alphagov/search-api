require "csv"
require "httparty"
require "json"

module Evaluate
  class Ndcg
    # NDCG calculates nDCG (https://en.wikipedia.org/wiki/Discounted_cumulative_gain#Normalized_DCG)
    # a measure of ranking quality, for a set of relevancy judgements.
    # Optional: any ab tests you wish to use, e.g. "relevance:B,popularity:C"
    # Returns { "average_ndcg" => 0.99, "tax" => 0.96, "harry potter" => 0.4 ... }
    def initialize(relevancy_judgements, ab_tests)
      @data = judgements_as_query_keyed_hash(relevancy_judgements)
      @search_params = DEFAULT_PARAMS.merge(ab_tests.nil? ? {} : { "ab_tests" => [ab_tests] })
      @search_config = SearchConfig.parse_parameters(@search_params).search_config
    end

    def compute_ndcg
      all = data.map do |(query, judgements)|
        { query => ndcg(ordered_ratings(query, judgements)) }
      end

      all = all.inject({}, :merge)
      average_ndcg = (all.values.inject(0) { |a, b| a + b }) / all.count
      all.merge("average_ndcg" => average_ndcg)
    end

  private

    DEFAULT_PARAMS = { "count" => ["10"], "fields" => ["link"] }

    attr_reader :data

    def judgements_as_query_keyed_hash(judgements)
      judgements.each_with_object({}) do |judgement, hsh|
        query = judgement[:query]
        hsh[query] = hsh.fetch(query, {})
        hsh[query][judgement[:id]] = judgement[:rank].to_i
      end
    end

    def ordered_ratings(query, ratings)
      search_results(query).map { |result| ratings[result["link"]] }.compact
    end

    def search_results(query)
      begin
        retries ||= 0
        SearchConfig.run_search(@search_params.merge("q" => [query])).fetch(:results, [])
      rescue StandardError
        sleep 5
        retry if (retries += 1) < 3
        nil
      end
    end

    def ndcg(ratings)
      return 0 if ratings.empty?

      dcg(ratings) / idcg(ratings)
    end

    def idcg(ratings)
      ideal_score = dcg(ratings.sort.reverse)
      return 1 if ideal_score <= 0

      ideal_score
    end

    def dcg(ratings)
      ratings
        .map
        .with_index { |rating, position|
          ((2 ** rating) - 1.0) / (Math.log2(position + 2.0))
        }
        .inject(0) { |total, score|
          total + score
        }
    end
  end
end
