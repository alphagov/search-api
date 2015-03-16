require "active_support/inflector"

class ResultSetPresenter

  def initialize(result_set, context = {}, schema = nil)
    @result_set = result_set
    @context = context
    @schema = schema
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
    result = expand_metadata(document.to_hash)

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

  def structure_by_slug(structure, slug)
    if item = structure && structure[slug]
      item.to_hash.merge("slug" => slug)
    else
      {"slug" => slug}
    end
  end

  def expand_metadata(document_attrs)
    if @schema.nil?
      return document_attrs
    end

    document_schema = schema_for_document(document_attrs)

    params_to_expand = document_attrs.select { |k, _|
      document_schema.allowed_values.include?(k)
    }

    expanded_params = params_to_expand.reduce({}) { |params, (field_name, values)|
      params.merge(
        field_name => Array(values).map { |raw_value|
          document_schema.allowed_values[field_name].find { |allowed_value|
            allowed_value.fetch("value") == raw_value
          }
        }
      )
    }

    document_attrs.merge(expanded_params)
  end

  def schema_for_document(document)
    index = document[:_metadata]["_index"]
    index_schema = @schema.schema_for_alias_name(index)
    index_schema.document_type(document_type(document))
  end

  def document_type(document)
    document.fetch(:_metadata, {}).fetch("_type", nil)
  end
end
