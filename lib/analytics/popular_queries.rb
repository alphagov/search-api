require "google/apis/analyticsreporting_v4"
require "analytics/reporting_requester"

module Analytics
  class PopularQueries
    include ReportRequester

    # PopularQueries gets the top search queries from Google Analytics.
    # Returns an array of searches and counts for the past 7 days
    # [
    #   ['universal credit', 1000000],
    #   ['tax', 1000000],
    #   ['vat', 1000000]
    # ]
    def queries
      parse_ga_response(authenticated_service.batch_get_reports(reports_request))
    end

  private

    def parse_ga_response(response)
      data = response.reports.first.data.rows || []
      data.map do |row|
        search_term = row.dimensions.first
        searches = Integer(row.metrics.first.values.first, 10)
        [search_term, searches]
      end
    end

    def reports_request
      GetReportsRequest.new(
        report_requests: [
          ReportRequest.new(
            view_id: ENV["GOOGLE_ANALYTICS_GOVUK_VIEW_ID"],
            metrics: [Metric.new(expression: "ga:searchUniques")],
            dimensions: [Dimension.new(name: "ga:searchKeyword")],
            sampling_level: "LARGE",
            order_bys: [
              OrderBy.new(
                field_name: "ga:searchUniques",
                sort_order: "DESCENDING",
              ),
            ],
          ),
        ],
      )
    end
  end
end
