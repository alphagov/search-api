module GovukIndex
  class DetailsPresenter
    extend MethodBuilder

    set_payload_method :details

    delegate_to_payload :licence_identifier
    delegate_to_payload :licence_short_description

    def initialize(details:, indexable_content_keys:, sanitiser:)
      @details = details
      @indexable_content_keys = indexable_content_keys
      @sanitiser = sanitiser
    end

    def indexable_content
      return nil if details.nil?
      @sanitiser.clean(indexable_content_parts + hidden_content)
    end

    def contact_groups
      details.fetch('contact_groups', []).map do |contact|
        contact['slug']
      end
    end

  private

    attr_reader :details

    def indexable_content_parts
      @indexable_content_keys.flat_map do |field|
        indexable_values = details[field] || []
        field == 'parts' ? parts(indexable_values) : [indexable_values]
      end
    end

    def parts(items)
      items.flat_map do |item|
        [item['title'], item['body']]
      end
    end

    def hidden_content
      Array(details.dig('metadata', 'hidden_indexable_content') || [])
    end
  end
end
