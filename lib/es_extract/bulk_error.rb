module EsExtract
  module BulkError
    module_function

    def error(item)
      EsExtract::BulkItem.error(item) || {}
    end

    def type(item)
      error(item)["type"]
    end

    def reason(item)
      error(item)["reason"]
    end

    def index(item)
      error(item)["index"]
    end

    def shard(item)
      error(item)["shard"]
    end

    def caused_by(item)
      error(item)["caused_by"] || {}
    end

    def caused_by_type(item)
      caused_by(item)["type"]
    end

    def caused_by_reason(item)
      caused_by(item)["reason"]
    end

    def present?(item)
      !error(item).empty?
    end
  end
end