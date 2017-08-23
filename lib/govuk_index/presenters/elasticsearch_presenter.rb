module GovukIndex
  class ElasticsearchPresenter
    def initialize(payload:, type:)
      @payload = payload
      @type = type
    end

    def identifier
      {
        _type: type,
        _id: base_path,
        version: payload["payload_version"],
        version_type: "external",
      }
    end

    def document
      {}.merge(CommonFieldsPresenter.new(payload, IndexableContentSanitiser.new).present)
        .merge(ExpandedLinksPresenter.new(payload["expanded_links"]).present)
    end

    def base_path
      @_base_path ||= payload["base_path"]
    end

    def valid!
      return if base_path
      raise(ValidationError, "base_path missing from payload")
    end

  private

    attr_reader :payload, :type
  end
end
