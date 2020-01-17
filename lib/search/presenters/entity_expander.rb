# EntityExpander
#
# Takes an elasticsearch result, which can have arrays of slugs and translates
# those into objects with extra data. For example, a result can contain
# organisations like this:
#
#   { "organisations": ["/mod"] }
#
# `#new_result(result)` will replace the slugs by an object from the
# organisations-registry (sourced from the government-index):
#
#  { "organisations": [{ "title": "Ministry of Defence", "slug": "/mod" }] }
#

module Search
  class EntityExpander
    attr_reader :registries

    def initialize(registries)
      @registries = registries
    end

    class Mapping
      attr_reader :registry_name, :field_name, :new_field_name

      def initialize(registry_name, new_field_name: nil)
        @registry_name = registry_name
        @field_name = registry_name.to_s
        @new_field_name = new_field_name.nil? ? @field_name : new_field_name.to_s
      end
    end

    MAPPINGS = [
      Mapping.new(:document_series),
      Mapping.new(:document_collections),
      Mapping.new(:organisations),
      Mapping.new(:policy_areas),
      Mapping.new(:world_locations),
      Mapping.new(:specialist_sectors),
      Mapping.new(:people),
      Mapping.new(:roles),
      Mapping.new(
        :topic_content_ids,
        new_field_name: :expanded_topics,
      ),
      Mapping.new(
        :organisation_content_ids,
        new_field_name: :expanded_organisations,
      ),
    ].freeze

    def new_result(result)
      MAPPINGS.each do |mapping|
        next unless result[mapping.field_name]

        registry = registries[mapping.registry_name]
        next unless registry

        result[mapping.new_field_name] = result[mapping.field_name].map do |field|
          fetch_expanded_version_by(field, registry, mapping)
        end
      end

      result
    end

  private

    def fetch_expanded_version_by(field, registry, mapping)
      if %i[topic_content_ids organisation_content_ids].include?(mapping.registry_name)
        item_from_registry_by_content_id(registry, field)
      else
        item_from_registry_by_slug(registry, field)
      end
    end

    def item_from_registry_by_slug(registry, slug)
      expanded_item = registry[slug] || {}

      expanded_item.merge("slug" => slug)
    end

    def item_from_registry_by_content_id(registry, content_id)
      expanded_item = registry.by_content_id(content_id) || {}

      expanded_item.merge("content_id" => content_id)
    end
  end
end
