require "csv"
require "httparty"
require "json"

module Debug
  class RankEval
    def initialize(datafile, ab_tests)
      @data = load_from_csv(datafile)
      @search_params = ab_tests.nil? ? {} : { "ab_tests" => [ab_tests] }
      @search_config = SearchConfig.parse_parameters(@search_params).search_config
    end

    def load_from_csv(datafile)
      data = {}
      last_query = ""
      CSV.foreach(datafile, headers: true) do |row|
        query = (row["query"] || last_query).strip
        score = row["score"]
        link = row["link"]

        raise "missing query for row '#{row}'" if query.nil?
        raise "missing score for row '#{row}'" if score.nil?
        raise "missing link for row '#{row}" if link.nil?

        data[query] = data.fetch(query, [])
        data[query] << ({ score: score.to_i, link: })

        last_query = query
      end

      ignore_extra_judgements(data)
    end

    def evaluate
      requests = queries.each_with_object([]) do |(query, data), acc|
        acc << {
          id: query,
          request: {
            query: data[:es_query][:query],
            post_filter: data[:es_query][:post_filter],
          },
          ratings: data[:judgements].map do |judgement|
            {
              _index: index_for_link(judgement[:link]),
              _id: judgement[:link],
              rating: judgement[:score],
            }
          end,
        }
      end

      result = rank_eval(requests)

      {
        score: result["metric_score"],
        query_scores: result["details"].transform_values do |detail|
          detail["metric_score"]
        end,
      }
    end

    def queries
      @queries ||= @data.each_with_object({}) do |(query, judgements), queries|
        queries[query] = {
          es_query: SearchConfig.generate_query(@search_params.merge("q" => [query])),
          judgements:,
        }
      end
    end

  private

    def rank_eval(requests)
      # This workaround was put in because the elasticsearch ruby client used to
      # have a bug that prevented us calling rank_eval with an index argument.
      # https://github.com/elastic/elasticsearch-ruby/pull/724
      # This bug has since been fixed, but removing this workaround means
      # that instead of using the httparty/net http timeout default,
      # we'd be using the elasticsearch timeout we have set, which is
      # not long enough for the rank_eval call. Because the timeout is a global
      # setting on the elasticsearch client, changing the timeout to only affect
      # the rank evaluation workflow would require a refactor.

      # @search_config.rank_eval(
      #   requests: requests,
      #   metric: { dcg: { k: 10, normalize: true } },
      # )

      uri = @search_config.base_uri
      options = {
        body: { requests:, metric: { dcg: { k: 10, normalize: true } } }.to_json,
        headers: { "Content-Type" => "application/json" },
      }
      indices = "*"
      url = "#{uri}/#{indices}/_rank_eval"
      response = HTTParty.post(url, options)
      puts "Elasticsearch: #{response.code}: #{response.message}"
      JSON.parse(response.body).with_indifferent_access
    end

    def ignore_extra_judgements(data)
      data.each_with_object({}) do |(query, non_unique_judgements), output|
        grouped_by_link = non_unique_judgements.uniq.group_by { |h| h[:link] }
        output[query] = grouped_by_link.map do |link, judgements|
          if judgements.count > 1
            puts "Ignoring #{judgements.count - 1} judgements for #{link} queried with query '#{query}'"
          end
          judgements.first
        end
      end
    end

    def index_for_link(link)
      return government_index_name if link.start_with? "/government/"

      govuk_index_name
    end

    def government_index_name
      @government_index_name ||= @search_config.get_index_for_alias(SearchConfig.content_index_names)
    end

    def govuk_index_name
      @govuk_index_name ||= @search_config.get_index_for_alias(SearchConfig.govuk_index_name)
    end
  end
end
