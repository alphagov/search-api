require "spec_helper"
require "analytics/ga4_import/data_fetcher"

RSpec.describe Analytics::Ga4Import::DataFetcher do
  let(:ga_client) { instance_double("::Google::Analytics::Data::V1beta::AnalyticsData::Client") }

  let(:run_report_response) do
    Google::Analytics::Data::V1beta::RunReportResponse.new(
      dimension_headers: [
        Google::Analytics::Data::V1beta::DimensionHeader.new(name: "pagePath"),
        Google::Analytics::Data::V1beta::DimensionHeader.new(name: "pageTitle"),
      ],
      metric_headers: [
        Google::Analytics::Data::V1beta::MetricHeader.new(
          name: "screenPageViews",
          type: :TYPE_INTEGER,
        ),
      ],
      rows:,
    )
  end
  let(:run_report_response_empty_rows) do
    Google::Analytics::Data::V1beta::RunReportResponse.new(
      dimension_headers: [
        Google::Analytics::Data::V1beta::DimensionHeader.new(name: "pagePath"),
        Google::Analytics::Data::V1beta::DimensionHeader.new(name: "pageTitle"),
      ],
      metric_headers: [
        Google::Analytics::Data::V1beta::MetricHeader.new(
          name: "screenPageViews",
          type: :TYPE_INTEGER,
        ),
      ],
      rows: [],
    )
  end
  let(:rows) do
    [
      Google::Analytics::Data::V1beta::Row.new(
        dimension_values: [
          Google::Analytics::Data::V1beta::DimensionValue.new(value: "/"),
          Google::Analytics::Data::V1beta::DimensionValue.new(value: "Welcome to GOV.UK"),
        ],
        metric_values: [
          Google::Analytics::Data::V1beta::MetricValue.new(value: "171078"),
        ],
      ),
      Google::Analytics::Data::V1beta::Row.new(
        dimension_values: [
          Google::Analytics::Data::V1beta::DimensionValue.new(value: "sign-in-universal-credit"),
          Google::Analytics::Data::V1beta::DimensionValue.new(value: "Sign in to your Universal Credit account - GOV.UK"),
        ],
        metric_values: [
          Google::Analytics::Data::V1beta::MetricValue.new(value: "184563"),
        ],
      ),
    ]
  end

  before do
    allow(::Google::Analytics::Data::V1beta::AnalyticsData::Client)
      .to receive_message_chain(:new, :run_report)
      .and_return(run_report_response, run_report_response_empty_rows)
  end

  describe "#call" do
    it "returns the correct data" do
      data = described_class.new.call
      expect(data).to match_array(
        [
          have_attributes(
            class: Analytics::Ga4Import::PageData,
            path: "/",
            title: "Welcome to GOV.UK",
            page_views: 171_078,
          ),
          have_attributes(
            class: Analytics::Ga4Import::PageData,
            path: "sign-in-universal-credit",
            title: "Sign in to your Universal Credit account - GOV.UK",
            page_views: 184_563,
          ),
        ],
      )
    end

    it "passes the correct offset and limit to the ReportRequestBuilder class" do
      report_request_builder = instance_double("Analytics::Ga4Import::ReportRequestBuilder")
      allow(report_request_builder).to receive(:report_request).and_return(an_instance_of(Google::Analytics::Data::V1beta::RunReportRequest))

      expect(Analytics::Ga4Import::ReportRequestBuilder)
        .to receive(:new)
        .with(
          Analytics::Ga4Import::DataFetcher::OFFSET,
          Analytics::Ga4Import::DataFetcher::LIMIT,
        ).and_return(report_request_builder)

      expect(Analytics::Ga4Import::ReportRequestBuilder)
        .to receive(:new)
        .with(
          Analytics::Ga4Import::DataFetcher::OFFSET + Analytics::Ga4Import::DataFetcher::OFFSET_INCREMENT,
          Analytics::Ga4Import::DataFetcher::LIMIT,
        ).and_return(report_request_builder)

      described_class.new.call
    end
  end
end
