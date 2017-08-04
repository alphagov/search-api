module Search
  class HighlightedDescription
    ELLIPSIS = "…".freeze

    attr_reader :raw_result

    def initialize(raw_result)
      @raw_result = raw_result
    end

    def text
      if highlighted_description
        highlighted_description_with_ellipses
      else
        truncated_original_description
      end
    end

  private

    def highlighted_description
      # `highlight` will be missing if none of the search terms match what's in
      # the title, eg. when displaying best bets.
      raw_result['highlight'] &&
        raw_result['highlight']['description'].to_a.first
    end

    # The highlighting will return a truncated version of the description. It
    # "centers" the truncation on the highlighted word, so that if the word
    # appears at the end of the description, it will strip off the first n chars.
    # When that has happened we'd like to add ellipsis to the truncated side(s).
    def highlighted_description_with_ellipses
      # The basic trick here is find out if the original and highlighted
      # versions are the same.
      escaped_original = Rack::Utils.escape_html(original_description)
      highlighted_without_tags = highlighted_description
        .gsub('<mark>', '').gsub('</mark>', '')

      output = highlighted_description

      unless escaped_original.starts_with?(highlighted_without_tags)
        output = ELLIPSIS + output
      end

      unless escaped_original.ends_with?(highlighted_without_tags)
        output = output + ELLIPSIS
      end

      output
    end

    def truncated_original_description
      Rack::Utils.escape_html(
        original_description.truncate(225, omission: ELLIPSIS)
      )
    end

    def original_description
      # `fields.description` is nil if the document doesn't have a description set.
      raw_result['fields']['description'] || ""
    end
  end
end
