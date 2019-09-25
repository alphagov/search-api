module GovukIndex
  class IndexableContentSanitiser
    def clean(items)
      cleaned_content = items.
        flat_map { |item| indexable_content(item) }.
        map { |item| strip_html_tags(item) }.
        compact

      return nil if cleaned_content.empty?
      cleaned_content.join("\n").strip
    end

  private

    def indexable_content(item)
      return [item] if item.instance_of?(String)
      return item if item.all? { |row| row.instance_of?(String) }
      [html_content(item)]
    end

    def html_content(item)
      row = item.detect { |r| r["content_type"] == "text/html" }
      return row["content"] if row

      if item.count > 0
        GovukError.notify(
          GovukIndex::MissingTextHtmlContentType.new,
          extra: { content_types: item.map { |r| r["content_type"] } }
        )
      end
      nil
    end

    def strip_html_tags(value)
      return nil unless value
      Loofah.document(value).to_text(encode_special_chars: false)
    end
  end
end
