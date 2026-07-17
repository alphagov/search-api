require "csv"

module Evaluation
  class RankEval
    def load_from_csv(datafile)
      data = {}
      last_query = ""
      CSV.foreach(datafile, headers: true) do |row|
        query = (row["queryEntry.query"] || last_query).strip
        score = row["queryEntry.targets.score"]
        content_id = row["queryEntry.targets.uri"]

        raise "missing query for row '#{row}'" if query.empty?
        raise "missing score for row '#{row}'" if score.nil?
        raise "missing content id for row '#{row}'" if content_id.nil?

        link = convert_to_link(content_id) || content_id

        data[query] = data.fetch(query, [])
        data[query] << ({ score: score.to_i, link: })

        last_query = query
      end

      ignore_extra_judgements(data)
    end

    def evaluate(csv_data)
      requests = queries(csv_data).each_with_object([]) do |(query, data), acc|
        acc << {
          id: query,
          request: {
            query: data[:es_query][:query],
            post_filter: data[:es_query][:post_filter],
          },
          ratings: data[:judgements].map do |judgement|
            {
              _index: govuk_index_name,
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

    def queries(csv_data)
      @queries ||= csv_data.each_with_object({}) do |(query, judgements), queries|
        queries[query] = {
          es_query: SearchConfig.generate_query({ "q" => [query] }),
          judgements:,
        }
      end
    end

  private

    def convert_to_link(data)
      return data if data.include?("/")

      Services
        .publishing_api
        .get_content(data)
        .to_h["base_path"]
    end

    def rank_eval(requests)
      client.rank_eval(
        index: SearchConfig.govuk_index_name,
        body: { requests:, metric: { dcg: { k: 10, normalize: true } } },
      )
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

    def govuk_index_name
      @govuk_index_name ||= client.indices.get_alias(index: SearchConfig.govuk_index_name).keys.first
    end

    def client
      @client ||= Services.elasticsearch(hosts: instance.base_uri, timeout: 120)
    end

    def instance
      @instance ||= SearchConfig.default_instance
    end
  end
end
