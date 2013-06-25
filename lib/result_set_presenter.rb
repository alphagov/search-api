class ResultSetPresenter

  def initialize(result_set, context = {})
    @result_set = result_set
    @context = context
  end

  def present
    presentable_hash = {
      total: @result_set.total,
      results: results
    }
    if spelling_suggestions
      presentable_hash[:spelling_suggestions] = spelling_suggestions
    end
    MultiJson.encode(presentable_hash)
  end

  PRESENTATION_FORMAT_TRANSLATION = {
    "planner" => "answer",
    "smart_answer" => "answer",
    "calculator" => "answer",
    "licence_finder" => "answer",
    "custom_application" => "answer",
    "calendar" => "answer"
  }

  FORMAT_NAME_ALTERNATIVES = {
    "programme" => "Benefits & credits",
    "transaction" => "Services",
    "local_transaction" => "Services",
    "place" => "Services",
    "answer" => "Quick answers",
    "specialist_guidance" => "Specialist guidance"
  }

private
  def presentation_format(document)
    normalized = normalized_format(document)
    PRESENTATION_FORMAT_TRANSLATION.fetch(normalized, normalized)
  end

  def humanized_format(document)
    presentation = presentation_format(document)
    FORMAT_NAME_ALTERNATIVES[presentation] || presentation.humanize.pluralize
  end

  def normalized_format(document)
    if document.format
      document.format.gsub("-", "_")
    else
      "unknown"
    end
  end

  def results
    @result_set.results.map { |document| build_result(document) }
  end

  def build_result(document)
    result = document.to_hash.merge(
      presentation_format: presentation_format(document),
      humanized_format: humanized_format(document)
    )
    if result['document_series'] && should_expand_document_series?
      result['document_series'] = result['document_series'].map do |slug|
        document_series_by_slug(slug)
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
    result
  end

  def should_expand_document_series?
    !! document_series_registry
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

  def organisation_registry
    @context[:organisation_registry]
  end

  def topic_registry
    @context[:topic_registry]
  end

  def world_location_registry
    @context[:world_location_registry]
  end

  def spelling_suggestions
    @context[:spelling_suggestions]
  end

  def document_series_by_slug(slug)
    document_series = document_series_registry && document_series_registry[slug]
    if document_series
      document_series.to_hash.merge(slug: slug)
    else
      {slug: slug}
    end
  end

  def organisation_by_slug(slug)
    organisation = organisation_registry && organisation_registry[slug]
    if organisation
      organisation.to_hash.merge(slug: slug)
    else
      {slug: slug}
    end
  end

  def topic_by_slug(slug)
    topic = topic_registry && topic_registry[slug]
    if topic
      topic.to_hash.merge(slug: slug)
    else
      {slug: slug}
    end
  end

  def world_location_by_slug(slug)
    world_location = world_location_registry && world_location_registry[slug]
    if world_location
      world_location.to_hash.merge(slug: slug)
    else
      {slug: slug}
    end
  end
end
