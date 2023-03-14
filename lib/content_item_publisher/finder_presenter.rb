module ContentItemPublisher
  class FinderPresenter < ContentItemPresenter
    def present_links
      default_links
    end

  private

    def email_alert_signup
      Array(content_item["signup_content_id"])
    end

    def content_item_parent
      Array(content_item["parent"])
    end

    def ordered_related_items
      Array(content_item["ordered_related_items"])
    end

    def facet_group
      facet_group = content_item.dig("links", "facet_group")
      facet_group ? { "facet_group" => facet_group } : {}
    end

    def default_links
      links = {
        "email_alert_signup" => email_alert_signup,
        "parent" => content_item_parent,
        "ordered_related_items" => ordered_related_items,
      }.merge(facet_group)

      { content_id:, links: }
    end
  end
end
