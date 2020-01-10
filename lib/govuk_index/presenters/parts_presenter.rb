module GovukIndex
  class PartsPresenter
    def initialize(parts: [])
      @parts = parts
    end

    def presented_parts
      return unless parts && parts.any?

      parts.map do |part|
        {
          "slug" => part["slug"],
          "title" => part["title"],
          "body" => summarise(part.fetch("body", [{}])),
        }
      end
    end

  private

    attr_reader :parts

    ELLIPSIS = "…".freeze
    SEPARATOR = " ".freeze

    def summarise(part_bodies)
      html = html_content(part_bodies)
      return unless html

      strip_html_tags(html).truncate(75, omission: ELLIPSIS, separator: SEPARATOR)
    end

    def html_content(part_bodies)
      part_body = part_bodies.detect { |body| body["content_type"] == "text/html" }
      return part_body["content"] if part_body

      if part_bodies.count.positive?
        GovukError.notify(
          GovukIndex::MissingTextHtmlContentType.new,
          extra: { content_types: part_bodies.map { |r| r["content_type"] } },
        )
      end
      nil
    end

    def strip_html_tags(value)
      Loofah.document(value).to_text(encode_special_chars: false).squish
    end
  end
end
