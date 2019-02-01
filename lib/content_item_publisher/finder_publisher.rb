module ContentItemPublisher
  class FinderPublisher < Publisher
  private

    def content_item_presenter
      FinderPresenter
    end
  end
end
