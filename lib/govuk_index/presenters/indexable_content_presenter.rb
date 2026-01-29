module GovukIndex
  class IndexableContentPresenter
    DEFAULTS = %w[body parts hidden_search_terms].freeze
    BY_FORMAT = {
      "contact" => %w[title description],
      "document_collection" => %w[collection_groups],
      "licence" => %w[licence_short_description licence_overview],
      "local_transaction" => %w[introduction more_information need_to_know],
      "operational_field" => %w[description],
      "transaction" => %w[introductory_paragraph more_information],
      "travel_advice" => %w[summary],
      "flood_and_coastal_erosion_risk_management_research_report" => %w[metadata.project_code],
    }.freeze

    def initialize(format:, details:, sanitiser:)
      @format    = format
      @details   = details
      @sanitiser = sanitiser
    end

    def indexable_content
      return nil if details.nil?

      sanitiser.clean(indexable)
    end

  private

    attr_reader :details, :format, :sanitiser

    def indexable
      indexable_content_parts + hidden_content + contact_groups_titles
    end

    def hidden_content
      Array(details.dig("metadata", "hidden_indexable_content") || [])
    end

    def indexable_content_parts
      indexable_content_keys.flat_map do |field|
        indexable_values = details.dig(*field.split(".")) || []
        %w[parts collection_groups].include?(field) ? indexable_values.flat_map { |item| [item["title"], item["body"]] } : [indexable_values]
      end
    end

    def indexable_content_keys
      DEFAULTS + BY_FORMAT.fetch(format, [])
    end

    def contact_groups_titles
      details.fetch("contact_groups", []).map { |contact| contact["title"] }
    end
  end
end
