require "active_support/inflector"

class ResultSetPresenter

  def initialize(result_set, context = {})
    @result_set = result_set
    @context = context
  end

  def present
    presentable_hash = {
      "total" => @result_set.total,
      "results" => results
    }
    if spelling_suggestions
      presentable_hash["spelling_suggestions"] = spelling_suggestions
    end
    presentable_hash
  end

private
  def results
    @result_set.results.map { |document| build_result(document) }
  end

  def build_result(document)
    result = document.to_hash

    if result['document_series'] && should_expand_document_series?
      result['document_series'] = result['document_series'].map do |slug|
        document_series_by_slug(slug)
      end
    end
    if result['document_collections'] && should_expand_document_collections?
      result['document_collections'] = result['document_collections'].map do |slug|
        document_collection_by_slug(slug)
      end
    end
    if result['organisations'] && should_expand_organisations?
      result['organisations'] = result['organisations'].map do |slug|
        organisation_by_slug(slug)
      end
    end
    if result['topics'] && should_expand_topics?
      result['topics'] = result['topics'].map do |slug|
        topic_by_slug(slug)
      end
    end
    if result['world_locations'] && should_expand_world_locations?
      result['world_locations'] = result['world_locations'].map do |slug|
        world_location_by_slug(slug)
      end
    end
    if result['specialist_sectors']
      result['specialist_sectors'].map! do |slug|
        sector_by_slug(slug)
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

  def document_series_registry
    @context[:document_series_registry]
  end

  def document_collection_registry
    @context[:document_collection_registry]
  end

  def organisation_registry
    @context[:organisation_registry]
  end

  def topic_registry
    @context[:topic_registry]
  end

  def world_location_registry
    @context[:world_location_registry]
  end

  def specialist_sector_registry
    @context[:specialist_sector_registry]
  end

  def spelling_suggestions
    @context[:spelling_suggestions]
  end

  def document_series_by_slug(slug)
    document_series = document_series_registry && document_series_registry[slug]
    if document_series
      document_series.to_hash.merge("slug" => slug)
    else
      {"slug" => slug}
    end
  end

  def document_collection_by_slug(slug)
    document_collection = document_collection_registry && document_collection_registry[slug]
    if document_collection
      document_collection.to_hash.merge("slug" => slug)
    else
      {"slug" => slug}
    end
  end

  def organisation_by_slug(slug)
    organisation = organisation_registry && organisation_registry[slug]
    if organisation
      organisation.to_hash.merge("slug" => slug)
    else
      {"slug" => slug}
    end
  end

  def topic_by_slug(slug)
    topic = topic_registry && topic_registry[slug]
    if topic
      topic.to_hash.merge("slug" => slug)
    else
      {"slug" => slug}
    end
  end

  def world_location_by_slug(slug)
    world_location = world_location_registry && world_location_registry[slug]
    if world_location
      world_location.to_hash.merge("slug" => slug)
    else
      {"slug" => slug}
    end
  end

  def sector_by_slug(slug)
    sector = specialist_sector_registry && specialist_sector_registry[slug]
    if sector
      sector.to_hash.merge("slug" => slug)
    else
      {"slug" => slug}
    end
  end
end
