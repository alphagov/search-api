module Analytics
  module Ga4Import
    class PageViewConsolidator
      def initialize(ga_data)
        @ga_data = ga_data
      end

      def consolidated_page_views
        @consolidated_page_views ||= ga_data
          .reject(&:excluded?)
          .group_by(&:normalised_path)
          .transform_values { |grouped_pages| grouped_pages.sum(&:page_views) }
          .sort_by { |_, views| -views }
          .to_h
      end

    private

      attr_reader :ga_data
    end
  end
end
