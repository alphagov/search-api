module ContentItemPublisher
  class FinderEmailSignupPublisher < Publisher
  private

    def content_item_presenter
      FinderEmailSignupPresenter
    end
  end
end
