module Analytics
  module Ga4Import
    class PageViewConsolidator
      MAX_PATH_LENGTH = 512

      def initialize(ga_data)
        @ga_data = ga_data
      end

      def consolidated_page_views
        ga_data
          .reject(&:excluded?)
          .reject { |page_data| page_data.path.bytesize >= MAX_PATH_LENGTH }
          .group_by(&:normalised_path)
          .transform_values { |grouped_pages| grouped_pages.sum(&:page_views) }
          .sort_by { |_, views| -views }
      end

    private

      attr_reader :ga_data
    end
  end
end
