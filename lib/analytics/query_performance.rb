require "analytics/reporting_requester"

module Analytics
  class QueryPerformance
    include ReportRequester

    # QueryPerformance gets the CTR for each of a given set of queries
    # Returns a set of queries and their top_n_ctr for the past 7 days
    # [
    #   [ "universal credit.top_1_ctr", 10 ],
    #   [ "universal credit.top_3_ctr", 23 ],
    #   [ "universal credit.top_5_ctr", 40 ],
    #   [ "tax.top_1_ctr", 12 ],
    #   [ "tax.top_2_ctr", 14 ],
    #   ...
    # ]
    def initialize(queries: [])
      @queries = queries
    end

    def call
      build_requests.map { |req|
        # This is a batch job that runs a few times per day, so it
        # is OK for it run slowly.
        sleep 3
        get_ctrs_for_batch(req)
      }.flatten(1)
    end

  private

    attr_reader :queries, :service

    def get_ctrs_for_batch(reports_request)
      retries ||= 0
      response = authenticated_service.batch_get_reports(reports_request)
      parse_ga_response(response).flatten(1)
    rescue Google::Apis::TransmissionError, Google::Apis::RateLimitError, Google::Apis::ServerError, Google::Apis::ClientError => e
      retry_wait_time = 5 * retries
      puts "Error fetching CTRS. Will retry in #{retry_wait_time} seconds... #{e}"
      sleep retry_wait_time
      retry if (retries += 1) < 3
      puts "retried #{retries} times to fetch reports, will abandon it"
      []
    end

    def parse_ga_response(response)
      response.reports.map do |query_report|
        hsh   = Hash.new(0)
        rows  = query_report.data.rows || []
        return [] if rows.empty?

        ctrs = rows.map.each_with_object(hsh) do |row, obj|
          position = row.dimensions.first
          ctr = Float(row.metrics.first.values.first)
          obj[position] = ctr
        end

        top_1_ctr = ctrs["1"]
        top_3_ctr = top_1_ctr + ctrs["2"] + ctrs["3"]
        top_5_ctr = top_3_ctr + ctrs["4"] + ctrs["5"]
        query = query_report.data.rows.first.dimensions.last

        [
          ["#{query}.top_1_ctr", top_1_ctr],
          ["#{query}.top_3_ctr", top_3_ctr],
          ["#{query}.top_5_ctr", top_5_ctr],
        ]
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
          metrics: [Metric.new(expression: "ga:productListCTR")],
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
