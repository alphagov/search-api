class EntityExpander
  def initialize(context)
    @context = context
  end

  def new_result(result)
    if result['document_series'] && should_expand_document_series?
      result['document_series'] = result['document_series'].map do |slug|
        structure_by_slug(document_series_registry, slug)
      end
    end

    if result['document_collections'] && should_expand_document_collections?
      result['document_collections'] = result['document_collections'].map do |slug|
        structure_by_slug(document_collection_registry, slug)
      end
    end

    if result['organisations'] && should_expand_organisations?
      result['organisations'] = result['organisations'].map do |slug|
        structure_by_slug(organisation_registry, slug)
      end
    end

    if result['topics'] && should_expand_topics?
      result['topics'] = result['topics'].map do |slug|
        structure_by_slug(topic_registry, slug)
      end
    end

    if result['world_locations'] && should_expand_world_locations?
      result['world_locations'] = result['world_locations'].map do |slug|
        structure_by_slug(world_location_registry, slug)
      end
    end

    if result['specialist_sectors']
      result['specialist_sectors'].map! do |slug|
        structure_by_slug(specialist_sector_registry, slug)
      end
    end

    if result['people'] && should_expand_people?
      result['people'].map! do |slug|
        structure_by_slug(people_registry, slug)
      end
    end

    result
  end

  def should_expand_document_series?
    !! document_series_registry
  end

  def should_expand_document_collections?
    !! document_collection_registry
  end

  def should_expand_organisations?
    !! organisation_registry
  end

  def should_expand_topics?
    !! topic_registry
  end

  def should_expand_world_locations?
    !! world_location_registry
  end

  def should_expand_people?
    !! people_registry
  end

  def document_series_registry
    @context[:document_series]
  end

  def document_collection_registry
    @context[:document_collections]
  end

  def organisation_registry
    @context[:organisations]
  end

  def topic_registry
    @context[:topics]
  end

  def world_location_registry
    @context[:world_locations]
  end

  def specialist_sector_registry
    @context[:specialist_sectors]
  end

  def people_registry
    @context[:people]
  end

  def structure_by_slug(structure, slug)
    if item = structure && structure[slug]
      item.to_hash.merge("slug" => slug)
    else
      {"slug" => slug}
    end
  end
end
