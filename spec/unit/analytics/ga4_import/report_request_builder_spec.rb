require "spec_helper"

RSpec.describe Analytics::Ga4Import::ReportRequestBuilder do
  describe "#report_request" do
    it "builds the correct RunReportRequest object" do
      analytics_data = described_class.new(0, 100).report_request
      start_date = Date.today.prev_day - 13
      end_date = Date.today.prev_day

      expect(analytics_data).to have_attributes(
        property: "properties/330577055",
        offset: 0,
        limit: 100,
        metric_aggregations: [],
        order_bys: [],
        currency_code: "",
        keep_empty_rows: false,
        return_property_quota: true,
      )

      expect(analytics_data.dimensions).to match_array(
        [
          have_attributes(
            class: Google::Analytics::Data::V1beta::Dimension,
            name: "pagePath",
          ),
          have_attributes(
            class: Google::Analytics::Data::V1beta::Dimension,
            name: "pageTitle",
          ),
        ],
      )

      expect(analytics_data.metrics).to match_array(
        [
          have_attributes(
            class: Google::Analytics::Data::V1beta::Metric,
            name: "screenPageViews",
            expression: "",
            invisible: false,
          ),
        ],
      )

      expect(analytics_data.date_ranges).to match_array(
        [
          have_attributes(
            class: Google::Analytics::Data::V1beta::DateRange,
            start_date: start_date.to_s,
            end_date: end_date.to_s,
          ),
        ],
      )
    end
  end
end
