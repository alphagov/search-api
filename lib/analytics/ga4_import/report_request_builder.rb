module Analytics
  module Ga4Import
    class ReportRequestBuilder
      attr_accessor :offset, :limit

      START_DATE = 13

      def initialize(offset, limit)
        @offset = offset
        @limit = limit
      end

      def report_request
        ::Google::Analytics::Data::V1beta::RunReportRequest.new({
          property: "properties/330577055",
          date_ranges: [
            date_range,
          ],
          dimensions: [page_path, page_title],
          metrics: [screen_page_views],
          offset:,
          limit:,
          return_property_quota: true,
        })
      end

    private

      def page_path
        # https://developers.google.com/analytics/devguides/reporting/data/v1/api-schema#dimensions
        Google::Analytics::Data::V1beta::Dimension.new(
          name: "pagePath",
        )
      end

      def page_title
        # https://developers.google.com/analytics/devguides/reporting/data/v1/api-schema#dimensions

        Google::Analytics::Data::V1beta::Dimension.new(
          name: "pageTitle",
        )
      end

      def screen_page_views
        # https://developers.google.com/analytics/devguides/reporting/data/v1/api-schema#metrics
        Google::Analytics::Data::V1beta::Metric.new(
          name: "screenPageViews",
        )
      end

      def date_range
        start_date = Date.today.prev_day - START_DATE
        end_date = Date.today.prev_day

        { start_date: start_date.to_s, end_date: end_date.to_s }
      end
    end
  end
end
