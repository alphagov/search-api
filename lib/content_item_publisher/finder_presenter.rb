module ContentItemPublisher
  class FinderPresenter < ContentItemPresenter
    def present_links
      links = {}
      links["email_alert_signup"] = email_alert_signup if email_alert_signup?
      links["parent"] = content_item_parent if content_item_parent?

      { content_id: content_id, links: links }
    end

  private

    def email_alert_signup?
      content_item.key?("signup_content_id")
    end

    def email_alert_signup
      [content_item["signup_content_id"]]
    end

    def content_item_parent?
      content_item.key?("parent")
    end

    def content_item_parent
      Array(content_item["parent"])
    end
  end
end
