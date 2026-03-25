module EsExtract
  module Aggregations
    module_function

    def names(aggs)
      aggs.keys
    end

    def aggregation(aggs, name)
      aggs[name.to_s] || {}
    end

    def buckets(aggs, name)
      Array(aggregation(aggs, name)["buckets"])
    end

    def buckets_from_response(response, name)
      buckets(EsExtract::Response.aggregations(response), name)
    end

    def meta(aggs, name)
      aggregation(aggs, name).reject { |k, _| k == "buckets" }
    end
  end
end
