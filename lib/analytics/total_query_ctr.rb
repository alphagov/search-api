require "analytics/reporting_requester"

module Analytics
  class TotalQueryCtr
    include ReportRequester

    # QueryPerformance gets the CTR for each of a given set of queries
    # Returns a set of queries and their absolute CTR for each position for the past 7 days
    # [
    #  {
    #   "universal credit" => {
    #     "1": 10,
    #     "2": 23,
    #     "3": 40,
    #     "4": 5,
    #   }
    #  }
    #  ...
    # ]
    def initialize(queries: [])
      @queries = queries
    end

    def call
      build_requests.map { |req| get_ctrs_for_batch(req) }.flatten(1)
    end

  private

    attr_reader :queries, :service

    def get_ctrs_for_batch(reports_request)
      begin
        retries ||= 0
        response = authenticated_service.batch_get_reports(reports_request)
        puts "Retry successful" if retries > 0
        parse_ga_response(response).flatten(1)
      rescue Google::Apis::TransmissionError => e
        puts "Error fetching CTRS. Will retry in 3 seconds... #{e}"
        sleep 3
        retry if (retries += 1) < 3
        []
      end
    end

    def parse_ga_response(response)
      response.reports.map do |query_report|
        hsh   = Hash.new(0)
        rows  = query_report.data.rows
        return [] unless rows && rows.any?

        query = query_report.data.rows.first.dimensions.last.downcase.gsub(' ', '_')

        rows.each_with_object({}) do |row, hsh|
          position = row.dimensions.first
          ctr = Float(row.metrics.first.values.first)

          hsh[query] ||= {}
          hsh[query][position] = ctr
        end
      end
    end

    def build_requests
      # GetReportsRequest can have a max of 5 report_requests.
      build_report_requests.in_groups_of(5).map do |report_reqs|
        GetReportsRequest.new(report_requests: report_reqs)
      end
    end

    def build_report_requests
      # rubocop:disable Metrics/BlockLength
      queries.map do |query|
        ReportRequest.new(
          view_id: ENV["GOOGLE_ANALYTICS_GOVUK_VIEW_ID"],
          include_empty_rows: true,
          metrics: [Metric.new(expression: "ga:productListCTR")],
          date_ranges: [
            DateRange.new(start_date: "2019-08-01", end_date: "2019-11-01")
          ],
          dimensions: [
            Dimension.new(name: "ga:productListPosition"),
            Dimension.new(name: "ga:dimension71"),
          ],
          sampling_level: "LARGE",
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
                DimensionFilter.new(
                  dimension_name: "ga:dimension71",
                  operator: "EXACT",
                  expressions: [query],
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
        )
        # rubocop:enable Metrics/BlockLength
      end
    end
  end
end
