module EsExtract
  module Hits
    module_function

    def array(response)
      Array(response.dig("hits", "hits"))
    end

    def total(response)
      total = response.dig("hits", "total")
      total.is_a?(Hash) ? total["value"] : total.to_i
    end

    def each(response, &block)
      array(response).each(&block)
    end

    # ---- individual hit ----

    def id(hit)
      hit["_id"]
    end

    def index(hit)
      hit["_index"]
    end

    def score(hit)
      hit["_score"]
    end

    def source(hit, *arg)
      hit.dig("_source", *arg)
    end

    def highlight(hit, field = nil)
      h = hit["highlight"] || {}
      field ? h[field.to_s] : h
    end

    def explanation(hit)
      hit["_explanation"]
    end
  end
end
