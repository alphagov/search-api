module GovukIndex
  class IndexableContentPresenter
    EXCLUDED_FIELDS = %w(
      continuation_link
      external_related_links
      licence_identifier
      will_continue_on
    ).freeze

    def initialize(details)
      @details = details
      @sanitiser = IndexableContentSanitiser.new
    end

    def indexable_content
      return nil if details.nil?
      sanitiser.clean(elements)
    end

  private

    attr_reader :details, :sanitiser

    def elements
      details.flat_map { |key, value|
        next if EXCLUDED_FIELDS.include?(key)
        key == 'parts' ? parts(value) : [value]
      }.compact
    end

    def parts(items)
      items.flat_map do |item|
        [item['title'], item['body']]
      end
    end
  end
end
