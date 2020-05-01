require "csv"
require "httparty"
require "json"

module Evaluate
  class Ndcg
    # NDCG calculates nDCG (https://en.wikipedia.org/wiki/Discounted_cumulative_gain#Normalized_DCG)
    # a measure of ranking quality, for a set of relevancy judgements.
    # Optional: any ab tests you wish to use, e.g. "relevance:disable,popularity:C"
    # Returns { "average_ndcg" => 0.99, "tax" => 0.96, "harry potter" => 0.4 ... }
    def initialize(relevancy_judgements, ab_tests)
      @field = field_used(relevancy_judgements)
      @data = judgements_as_query_keyed_hash(relevancy_judgements)
      @search_params = DEFAULT_PARAMS.merge(ab_tests.nil? ? {} : { "ab_tests" => [ab_tests] })
      @search_config = SearchConfig.parse_parameters(@search_params).search_config
    end

    def compute_ndcg
      return { "average_ndcg" => default_ndcg(0) } if data.empty?

      all = data.map do |(query, judgements)|
        { query => ndcg(ordered_ratings(query, judgements)) }
      end

      all = all.inject({}, :merge)
      all.merge("average_ndcg" => average_ndcg(all.values))
    end

  private

    DEFAULT_PARAMS = { "count" => %w[20], "fields" => %w[link content_id] }.freeze

    attr_reader :data, :field

    def field_used(judgements)
      judgements.any? && judgements.first[:link].present? ? "link" : "content_id"
    end

    def average_ndcg(ndcg_scores)
      summed = ndcg_scores.inject(default_ndcg(0)) { |a, b|
        {
          "1" => a["1"] + b["1"],
          "3" => a["3"] + b["3"],
          "5" => a["5"] + b["5"],
          "10" => a["10"] + b["10"],
          "20" => a["20"] + b["20"],
        }
      }

      count = ndcg_scores.count

      {
        "1" => summed["1"] / count,
        "3" => summed["3"] / count,
        "5" => summed["5"] / count,
        "10" => summed["10"] / count,
        "20" => summed["20"] / count,
      }
    end

    def judgements_as_query_keyed_hash(judgements)
      judgements.each_with_object({}) do |judgement, hsh|
        query = judgement[:query]
        hsh[query] = hsh.fetch(query, {})
        hsh[query][judgement[field.to_sym]] = judgement[:score].to_i
      end
    end

    def ordered_ratings(query, ratings)
      search_results(query).first(20).map { |result| ratings[result[field]] }.compact
    end

    def search_results(query)
      retries ||= 0
      SearchConfig.run_search(@search_params.merge("q" => [query])).fetch(:results, [])
    rescue StandardError => e
      puts e
      sleep 2
      retry if (retries += 1) < 3
      nil
    end

    def ndcg(ratings)
      return default_ndcg(0) if ratings.empty?

      {
        "1" => dcg(ratings, 1) / idcg(ratings, 1),
        "3" => dcg(ratings, 3) / idcg(ratings, 3),
        "5" => dcg(ratings, 5) / idcg(ratings, 5),
        "10" => dcg(ratings, 10) / idcg(ratings, 10),
        "20" => dcg(ratings, 20) / idcg(ratings, 20),
      }
    end

    def idcg(ratings, count)
      ratings = ratings.first(count)
      ideal_score = dcg(ratings.sort.reverse, count)
      return 1 if ideal_score <= 0

      ideal_score
    end

    def default_ndcg(value)
      {
        "1" => value,
        "3" => value,
        "5" => value,
        "10" => value,
        "20" => value,
      }
    end

    def dcg(ratings, count)
      ratings = ratings.first(count)
      processed = ratings.map.with_index { |rating, position|
        ((2**rating) - 1.0) / Math.log2(position + 2.0)
      }
      processed.inject(0) { |total, score| total + score }
    end
  end
end
