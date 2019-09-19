require 'csv'

module Debug
  class RankEval
    def initialize(datafile, ab_tests)
      @ab_tests = ab_tests
      @data = load_from_csv(datafile)
      @search_config = SearchConfig.parse_parameters('ab_tests' => [ab_tests]).search_config
    end

    def load_from_csv(datafile)
      data = {}
      last_query = ""
      CSV.foreach(datafile, headers: true) do |row|
        query = (row['query'] || last_query).strip
        score = row['score']
        link = row['link']

        raise "missing query for row '#{row}'" if query.nil?
        raise "missing score for row '#{row}'" if score.nil?
        raise "missing link for row '#{row}" if link.nil?

        data[query] = data.fetch(query, [])
        data[query] << { score: score.to_i, link: link }

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
            post_filter: data[:es_query][:post_filter]
          },
          ratings: data[:judgements].map do |judgement|
            {
              _index: index_for_link(judgement[:link]),
              _id: judgement[:link],
              rating: judgement[:score],
            }
          end
        }
      end

      result = @search_config.rank_eval(
        requests: requests,
        metric: { dcg: { k: 10 } }
      )

      {
        score: result['metric_score'],
        query_scores: result['details'].each_with_object({}) do |(query, detail), acc|
          acc[query] = detail['metric_score']
        end
      }
    end

    def queries
      @queries ||= @data.each_with_object({}) do |(query, judgements), queries|
        queries[query] = {
          es_query: SearchConfig.generate_query(
            'q' => [query],
            'ab_tests' => [@ab_tests]
          ),
          judgements: judgements
        }
      end
    end

  private

    def ignore_extra_judgements(data)
      data.each_with_object({}) do |(query, non_unique_judgements), output|
        grouped_by_link = non_unique_judgements.uniq.group_by { |h| h[:link] }
        output[query] = grouped_by_link.map { |link, judgements|
          if judgements.count > 1
            puts "Ignoring #{judgements.count - 1} judgements for #{link} queried with query '#{query}'"
          end
          judgements.first
        }
      end
    end

    def index_for_link(link)
      return detailed_index_name if link.start_with? '/guidance/'

      return government_index_name if link.start_with? '/government/'

      govuk_index_name
    end

    def detailed_index_name
      @detailed_index_name ||= @search_config.get_index_for_alias('detailed')
    end

    def government_index_name
      @government_index_name ||= @search_config.get_index_for_alias('government')
    end

    def govuk_index_name
      @govuk_index_name ||= @search_config.get_index_for_alias('govuk')
    end
  end
end
