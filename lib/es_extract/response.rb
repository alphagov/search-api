module EsExtract
  module Response
    module_function

    def hits(response)
      response["hits"] || {}
    end

    def aggregations(response)
      response["aggregations"] || {}
    end

    def suggest(response)
      response["suggest"] || {}
    end

    def scroll_id(response)
      response["_scroll_id"]
    end

    def agg(response, name)
      aggregations(response)[name] || {}
    end

    # Works for:
    # - terms aggs
    # - filter aggs with sub-aggs
    def buckets(response, name, sub_agg = nil)
      node = agg(response, name)

      return node["buckets"] if node["buckets"]

      node = node[sub_agg] if sub_agg

      node&.fetch("buckets", nil) ||
        node&.values&.find { |v| v.is_a?(Hash) && v["buckets"] }&.fetch("buckets")
    end

    def doc_count(response, name)
      agg(response, name)["doc_count"]
    end
  end
end
