module ContentItemPublisher
  class FacetGroupFinderPresenter < FinderPresenter
    def present_links
      links = default_links
      links[:links]["facet_group"] = Array(content_item.fetch("links", {}).fetch("facet_group", nil))
      links
    end
  end
end
