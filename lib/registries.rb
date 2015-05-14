require "registry"

class Registries < Struct.new(:search_server, :search_config)
  def [](name)
    as_hash[name]
  end

  def as_hash
    @registries ||= {
      organisations: organisations,
      topics: topics,
      document_series: document_series,
      document_collections: document_collections,
      world_locations: world_locations,
      specialist_sectors: specialist_sectors,
      people: people,
    }
  end

  def organisations
    index_name = search_config.organisation_registry_index
    @organisations ||= Registry::Organisation.new(
      index_for_search(index_name),
      field_definitions
    ) if index_name
  end

  def topics
    index_name = search_config.topic_registry_index
    @topics ||= Registry::Topic.new(
      index_for_search(index_name),
      field_definitions
    ) if index_name
  end

  def document_series
    index_name = search_config.document_series_registry_index
    @document_series ||= Registry::DocumentSeries.new(
      index_for_search(index_name),
      field_definitions
    ) if index_name
  end

  def document_collections
    index_name = search_config.document_collection_registry_index
    @document_collections ||= Registry::DocumentCollection.new(
      index_for_search(index_name),
      field_definitions
    ) if index_name
  end

  def world_locations
    index_name = search_config.world_location_registry_index
    @world_locations ||= Registry::WorldLocation.new(
      index_for_search(index_name),
      field_definitions
    ) if index_name
  end

  def specialist_sectors
    index_name = settings.search_config.govuk_index_names
    @specialist_sector_registry ||= Registry::SpecialistSector.new(
      index_for_search(index_name),
      field_definitions
    )
  end

  def people
    index_name = settings.search_config.people_registry_index
    @people_registry ||= Registry::Person.new(
      index_for_search(index_name),
      field_definitions
    )
  end

  private

  def index_for_search(index_name)
    search_server.index_for_search(
      index_name.is_a?(Array) ? index_name : [index_name]
    )
  end

  def field_definitions
    @field_definitions ||= search_server.schema.field_definitions
  end
end
