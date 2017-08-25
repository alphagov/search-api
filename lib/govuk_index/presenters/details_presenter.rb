module GovukIndex
  class DetailsPresenter
    ALLOWED_FIELDS = %w(body licence_overview licence_short_description parts).freeze

    def initialize(details)
      @details = details
      @sanitiser = IndexableContentSanitiser.new
    end

    def indexable_content
      return nil if details.nil?
      sanitiser.clean(elements)
    end

    def licence_identifier
      details['licence_identifier']
    end

    def licence_short_description
      details['licence_short_description']
    end

  private

    attr_reader :details, :sanitiser

    def elements
      content = details.flat_map do |key, value|
        next unless ALLOWED_FIELDS.include?(key)
        key == 'parts' ? parts(value) : [value]
      end
      content.compact
    end

    def parts(items)
      items.flat_map do |item|
        [item['title'], item['body']]
      end
    end
  end
end
