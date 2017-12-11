module Search
  class HighlightedTitle
    def initialize(raw_result)
      @title = HighlightedField.new("title", raw_result)
    end

    def text
      @title.highlighted || @title.original
    end
  end
end
