module GovukIndex
  class CommonFieldsPresenter
    def initialize(payload, sanitiser)
      @payload = payload
      @sanitiser = sanitiser
    end

    def present
      {
        content_id: payload["content_id"],
        content_store_document_type: payload["document_type"],
        description: payload["description"],
        email_document_supertype: payload["email_document_supertype"],
        format: payload["document_type"],
        government_document_supertype: payload["government_document_supertype"],
        indexable_content: sanitiser.clean(payload),
        is_withdrawn: withdrawn?,
        link: payload["base_path"],
        navigation_document_supertype: payload["navigation_document_supertype"],
        popularity: calculate_popularity,
        public_timestamp: payload["public_updated_at"],
        publishing_app: payload["publishing_app"],
        rendering_app: payload["rendering_app"],
        title: payload["title"],
        user_journey_document_supertype: payload["user_journey_document_supertype"],
      }
    end

  private

    attr_reader :payload, :sanitiser

    def withdrawn?
      !payload["withdrawn_notice"].nil?
    end

    def calculate_popularity
      lookup = Indexer::PopularityLookup.new("govuk_index", SearchConfig.instance)
      lookup.lookup_popularities([payload["base_path"]])[payload["base_path"]]
    end
  end
end
