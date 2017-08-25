module GovukIndex
  class DetailsPresenter
    DEFAULT_FIELDS = %w(body parts).freeze
    FIELDS_BY_FORMAT = {
      'licence'     => %w(licence_short_description licence_overview),
      'transaction' => %w(introductory_paragraph more_information)
    }.freeze

    def initialize(details:, format:, sanitiser:)
      @details = details
      @format = format
      @sanitiser = sanitiser
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

    attr_reader :details, :format, :sanitiser

    def elements
      content = allowed_fields.flat_map do |field|
        indexable_values = details[field] || []
        field == 'parts' ? parts(indexable_values) : [indexable_values]
      end
      content.compact
    end

    def allowed_fields
      DEFAULT_FIELDS + fields_by_format
    end

    def fields_by_format
      FIELDS_BY_FORMAT[format] || []
    end

    def parts(items)
      items.flat_map do |item|
        [item['title'], item['body']]
      end
    end
  end
end
