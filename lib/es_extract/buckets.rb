module EsExtract
  module Buckets
    module_function

    def key(bucket)
      bucket["key"]
    end

    def doc_count(bucket)
      bucket["doc_count"]
    end

    def docs(bucket)
      bucket["docs"] || []
    end

    def sub_agg(bucket, name)
      bucket[name.to_s] || {}
    end

    def each(response, agg_name, &block)
      EsExtract::Aggs.buckets_from_response(response, agg_name).each(&block)
    end
  end
end