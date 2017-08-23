module GovukIndex
  class CommonFieldsPresenter
    def initialize(payload)
      @payload = payload
    end

    def content_id
      payload["content_id"]
    end

    def content_store_document_type
      payload["document_type"]
    end

    def description
      payload["description"]
    end

    def email_document_supertype
      payload["email_document_supertype"]
    end

    def format
      payload["document_type"]
    end

    def government_document_supertype
      payload["government_document_supertype"]
    end

    def is_withdrawn
      !payload["withdrawn_notice"].nil?
    end

    def link
      payload["base_path"]
    end

    def navigation_document_supertype
      payload["navigation_document_supertype"]
    end

    def popularity
      lookup = Indexer::PopularityLookup.new("govuk_index", SearchConfig.instance)
      lookup.lookup_popularities([payload["base_path"]])[payload["base_path"]]
    end

    def public_timestamp
      payload["public_updated_at"]
    end

    def publishing_app
      payload["publishing_app"]
    end

    def rendering_app
      payload["rendering_app"]
    end

    def title
      payload["title"]
    end

    def user_journey_document_supertype
      payload["user_journey_document_supertype"]
    end

  private

    attr_reader :payload
  end
end
