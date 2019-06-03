module ContentItemPublisher
  class ContentItemPresenter
    attr_reader :content_id, :content_item, :timestamp

    def initialize(content_item, timestamp)
      @content_item = content_item
      @content_id = content_item["content_id"]
      @timestamp = timestamp
    end

    def present
      {
        base_path: content_item["base_path"],
        description: content_item["description"],
        details: content_item["details"],
        document_type: content_item["document_type"],
        locale: "en",
        phase: content_item["phase"] || "live",
        public_updated_at: timestamp,
        publishing_app: "search-api",
        rendering_app: "finder-frontend",
        routes: content_item["routes"],
        schema_name: content_item["schema_name"],
        title: content_item["title"],
        update_type: "minor",
      }
    end

    def present_links
      { content_id: content_id, links: {} }
    end

    def description
      "#{present[:title]} (a #{present[:schema_name]} content item)"
    end
  end
end
