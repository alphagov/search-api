module GovukIndex
  class IndexableContentPresenter
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
      details.flat_map do |key, value|
        key == 'parts' ? parts(value) : [value]
      end
    end

    def parts(items)
      items.flat_map do |item|
        [item['title'], item['body']]
      end
    end
  end
end
