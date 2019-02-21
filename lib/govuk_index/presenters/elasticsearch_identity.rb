module GovukIndex
  module ElasticsearchIdentity
    # Documents are uniquely identified by the combination of index
    # and id.  We also use external versioning to keep in sync with
    # the publishing API.
    def identifier
      raise UnknownDocumentTypeError unless type

      {
        _type: 'generic-document',
        _id: id,
        version: payload["payload_version"],
        version_type: "external",
      }
    end

    # Internal content uses the base_path as the ID
    # External content uses the content id
    def id
      base_path || payload["content_id"]
    end

    # Implement in classes
    def type
      raise NotImplementedError
    end
  end
end
