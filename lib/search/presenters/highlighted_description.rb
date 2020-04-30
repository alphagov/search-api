module Search
  class HighlightedDescription
    ELLIPSIS = "…".freeze

    attr_reader :raw_result

    def initialize(raw_result)
      @raw_result = raw_result
      @description = HighlightedField.new("description", raw_result)
    end

    def text
      if description.highlighted
        highlighted_description_with_ellipses
      else
        truncated_original_description
      end
    end

  private

    attr_reader :description

    # The highlighting will return a truncated version of the description. It
    # "centers" the truncation on the highlighted word, so that if the word
    # appears at the end of the description, it will strip off the first n chars.
    # When that has happened we'd like to add ellipsis to the truncated side(s).
    def highlighted_description_with_ellipses
      # The basic trick here is find out if the original and highlighted
      # versions are the same.
      highlighted_without_tags = description.highlighted
        .gsub("<mark>", "").gsub("</mark>", "")

      output = description.highlighted

      unless description.original.starts_with?(highlighted_without_tags)
        output = ELLIPSIS + output
      end

      unless description.original.ends_with?(highlighted_without_tags)
        output += ELLIPSIS
      end

      output
    end

    def truncated_original_description
      description.original.truncate(225, omission: ELLIPSIS)
    end
  end
end
