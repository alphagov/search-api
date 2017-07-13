module GovukIndex
  class ElasticsearchPresenter
    def initialize(payload)
      @payload = payload
    end

    def identifier
      {
        _type: payload["document_type"],
        _id: payload["base_path"]
      }
    end

    def document
      {
        link: payload["base_path"],
        title: payload["title"]
      }
    end

    def valid!
      return if payload["base_path"]
      raise(ValidationError, "base_path missing from payload")
    end

  private

    attr_reader :payload
  end
end
