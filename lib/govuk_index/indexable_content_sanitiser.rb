module GovukIndex
  class IndexableContentSanitiser
    def clean(items)
      cleaned_content = items.map { |item|
        strip_html_tags(indexable_content(item))
      }.compact

      return nil if cleaned_content.empty?
      cleaned_content.join("\n").strip
    end

  private

    def indexable_content(item)
      item.instance_of?(String) ? item : html_content(item)
    end

    def html_content(item)
      row = item.detect { |r| r['content_type'] == 'text/html' }
      return row['content'] if row

      if item.count > 0
        GovukError.notify(
          GovukIndex::MissingTextHtmlContentType.new,
          extra: { content_types: item.map { |r| r['content_type'] } }
        )
      end
      nil
    end

    def strip_html_tags(value)
      return nil unless value
      Loofah.document(value).to_text
    end
  end
end
