module Analytics
  module Ga4Import
    class DataFetcher
      attr_accessor :ga_client

      LIMIT = 10_000

      def initialize
        @ga_client = ::Google::Analytics::Data::V1beta::AnalyticsData::Client.new
      end

      def call
        # https://developers.google.com/analytics/devguides/reporting/data/v1/basics#navigate_long_reports
        offset = 0
        all_data = []

        loop do
          data = get_data(offset)
          break if data.nil? || data[:rows].nil?

          all_data << format_all_data(data[:rows])

          offset += LIMIT
        end

        all_data.flatten
      end

    private

      def format_all_data(data)
        data.map do |row|
          path = row[:dimension_values].first[:value]
          title = row[:dimension_values].last[:value]
          page_views = row[:metric_values].first[:value]

          PageData.new(path, title, page_views)
        end
      end

      def get_data(offset)
        report_request_builder = ReportRequestBuilder.new(offset, LIMIT)
        ga_response = ga_client.run_report(report_request_builder.report_request)
        ga_response.to_h
      end
    end
  end
end
