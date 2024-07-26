module Analytics
  module Ga4Import
    class PageData
      PAGE_NOT_FOUND_TITLE = "Page not found".freeze

      attr_reader :path, :title, :page_views

      def initialize(path, title, page_views)
        @path = path
        @title = title
        @page_views = page_views.to_i
      end

      def excluded?
        non_relative_path? || smart_answer? || not_found?
      end

      def normalised_path
        path.partition("?").first.chomp("/").presence || "/"
      end

    private

      def non_relative_path?
        !normalised_path.start_with?("/")
      end

      def smart_answer?
        normalised_path.include?("/y/")
      end

      def not_found?
        title.include?(PAGE_NOT_FOUND_TITLE)
      end
    end
  end
end
