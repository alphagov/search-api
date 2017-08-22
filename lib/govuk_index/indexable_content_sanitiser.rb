module GovukIndex
  class IndexableContentSanitiser
    def clean(payload)
      return nil if payload['details'].nil?

      cleaned_content = payload['details'].values.map { |item|
        strip_html_tags(indexable_content(item))
      }.compact

      return nil if cleaned_content.empty?
      cleaned_content.join("\n")
    end

  private

    def indexable_content(item)
      item.instance_of?(String) ? item : html_content(item)
    end

    def html_content(item)
      row = item.detect { |r| r['content_type'] == 'text/html' }
      return row['content'] if row

      if item.count > 0
        GOVUK::Error.notify(
          GovukIndex::MissingTextHtmlContentType.new,
          parameters: { content_types: item.map { |r| r['content_type'] } }
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
