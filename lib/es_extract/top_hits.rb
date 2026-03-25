module EsExtract
  #This is used to extract data about the top hits in an aggregation
  module TopHits
    module_function

    def hits(bucket, name)
      Array(bucket.dig(name.to_s, "hits", "hits"))
    end

    def total(bucket, name)
      total = bucket.dig(name.to_s, "hits", "total")
      total.is_a?(Hash) ? total["value"] : total.to_i
    end
  end
end
