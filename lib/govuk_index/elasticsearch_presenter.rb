module GovukIndex
  class ElasticsearchPresenter
    def initialize(payload:, type:, sanitiser:)
      @payload = payload
      @type = type
      @sanitiser = sanitiser
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
      {
        content_id: payload["content_id"],
        content_store_document_type: payload["document_type"],
        description: payload["description"],
        format: payload["document_type"],
        indexable_content: sanitiser.clean(payload),
        is_withdrawn: withdrawn?,
        link: base_path,
        mainstream_browse_pages: [],
        mainstream_browse_page_content_ids: [],
        organisations: organisations_titles,
        organisation_content_ids: organisation_content_ids,
        part_of_taxonomy_tree: [],
        popularity: calculate_popularity,
        primary_publishing_organisation: [],
        public_timestamp: payload["public_updated_at"],
        publishing_app: payload["publishing_app"],
        rendering_app: payload["rendering_app"],
        specialist_sectors: topics,
        taxons: [],
        topic_content_ids: [],
        title: payload["title"],
      }
    end

    def base_path
      @_base_path ||= payload["base_path"]
    end

    def valid!
      return if base_path
      raise(ValidationError, "base_path missing from payload")
    end

  private

    attr_reader :payload, :sanitiser, :type

    def withdrawn?
      !payload["withdrawn_notice"].nil?
    end

    def expanded_links
      payload["expanded_links"] || {}
    end

    def organisations
      expanded_links["organisations"] || {}
    end

    def organisations_titles
      organisations.map { |org| org["title"] }
    end

    def organisation_content_ids
      organisations.map { |org| org["content_id"] }
    end

    def topics
      []
    end

    def calculate_popularity
      lookup = Indexer::PopularityLookup.new("govuk_index", SearchConfig.instance)
      lookup.lookup_popularities([base_path])[base_path]
    end
  end
end
