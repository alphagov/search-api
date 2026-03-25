module EsExtract
  module Bulk
    module_function

    def took(response)
      response["took"]
    end

    def errors?(response)
      response["errors"] == true
    end

    def items(response)
      Array(response["items"])
    end

    def each(response, &block)
      items(response).each(&block)
    end

    def actions(response)
      items(response).map { |item| item.keys.first }
    end

    def successful?(response)
      !errors?(response)
    end

    # Only items that failed
    def failures(response)
      items(response).select do |item|
        action = item.values.first
        action["error"]
      end
    end

    # Only successful items
    def successes(response)
      items(response).reject do |item|
        action = item.values.first
        action["error"]
      end
    end
  end
end