module EsExtract
  module BulkItem
    module_function

    def action(item)
      item.keys.first
    end

    def data(item)
      item.values.first || {}
    end

    def id(item)
      data(item)["_id"]
    end

    def index(item)
      data(item)["_index"]
    end

    def status(item)
      data(item)["status"]
    end

    def result(item)
      data(item)["result"]
    end

    def error(item)
      data(item)["error"]
    end

    def error?(item)
      !!error(item)
    end

    def success?(item)
      !error?(item)
    end
  end
end