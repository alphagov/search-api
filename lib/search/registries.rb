module Search
  Registries = Struct.new(:search_server, :search_config) do
    def [](name)
      as_hash[name]
    end

    def as_hash
      @as_hash ||= {
        organisations:,
        organisation_content_ids: organisations,
        document_collections: govuk_registry_for_document_format("document_collection"),
        world_locations: govuk_registry_for_document_format("world_location"),
        people: govuk_registry_for_document_format("person"),
        roles: govuk_registry_for_document_format("ministerial_role"),
      }
    end

  private

    def organisations
      BaseRegistry.new(
        govuk_index,
        field_definitions,
        "organisation",
        %w[
          slug
          content_id
          link
          title
          acronym
          organisation_type
          organisation_closed_state
          organisation_state
          logo_formatted_title
          organisation_brand
          organisation_crest
          logo_url
          closed_at
          public_timestamp
          analytics_identifier
          child_organisations
          parent_organisations
          superseded_organisations
          superseding_organisations
        ],
      )
    end

    def govuk_registry_for_document_format(format)
      BaseRegistry.new(govuk_index, field_definitions, format)
    end

    def govuk_index
      search_server.index(SearchConfig.govuk_index_name)
    end

    def field_definitions
      @field_definitions ||= search_server.schema.field_definitions
    end
  end
end
