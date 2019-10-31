require "analytics/reporting_requester"

module Analytics
  class OverallCTR
    include ReportRequester

    # OverallCTR gets the aggregate click-through-rate (CTR) for
    # individual site search results from Google Analytics.
    # Returns a set of click through rates for the past 7 days:
    # [
    #   ["top_1_ctr", 25],
    #   ["top_3_ctr", 50],
    #   ["top_5_ctr", 70]
    # ]
    def call
      response = authenticated_service.batch_get_reports(reports_request)
      parse_ga_response(response)
    end

  private

    def parse_ga_response(response)
      default_hsh = Hash.new(0)
      reports = response.reports.first.data.rows.each_with_object(default_hsh) do |row, hsh|
        position = row.dimensions.first
        ctr = Float(row.metrics.first.values.first)
        hsh[position] = ctr
      end

      top_1_ctr = reports["1"]
      top_3_ctr = top_1_ctr + reports["2"] + reports["3"]
      top_5_ctr = top_3_ctr + reports["4"] + reports["5"]

      [
        ["top_1_ctr", top_1_ctr],
        ["top_3_ctr", top_3_ctr],
        ["top_5_ctr", top_5_ctr],
      ]
    end

    def reports_request
      GetReportsRequest.new(
        report_requests: [
          ReportRequest.new(
            view_id: ENV["GOOGLE_ANALYTICS_GOVUK_VIEW_ID"],
            page_size: 10,
            metrics: [
              Metric.new(expression: "ga:productListCTR"),
              Metric.new(expression: "ga:productListClicks"),
            ],
            dimensions: [
              Dimension.new(name: "ga:productListPosition"),
              Dimension.new(name: "ga:productListName"),
            ],
            dimension_filter_clauses: [
              DimensionFilterClause.new(
                operator: "AND",
                filters: [
                  DimensionFilter.new(
                    dimension_name: "ga:productListPosition",
                    expressions: ["^[0-9]{1,1}$"],
                  ),
                  DimensionFilter.new(
                    dimension_name: "ga:productListName",
                    operator: "EXACT",
                    case_sensitive: false,
                    expressions: %w[Search],
                  ),
                ],
              ),
            ],
            order_bys: [
              OrderBy.new(
                field_name: "ga:productListPosition",
                sort_order: "ASCENDING",
              ),
            ],
          ),
        ],
      )
    end
  end
end
