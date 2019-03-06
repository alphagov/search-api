module ContentItemPublisher
  class FinderPresenter < ContentItemPresenter
    def present_links
      links = { "email_alert_signup" => email_alert_signup,
               "parent" => content_item_parent }

      { content_id: content_id, links: links }
    end

  private
    def email_alert_signup
      Array(content_item["signup_content_id"])
    end

    def content_item_parent
      Array(content_item["parent"])
    end
  end
end
