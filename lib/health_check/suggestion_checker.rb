require "csv"
require "health_check/calculator"
require "health_check/suggestion_check"

module HealthCheck
  class SuggestionChecker
    def initialize(options = {})
      @test_data_file = options[:test_data]
      @search_client = options[:search_client]
    end

    def run!
      Logging.logger[self].info("Connecting to #{@search_client.to_s}")

      calculator = Calculator.new

      parsed_checks.each do |search_term, expected_result|
        suggested_queries = @search_client.search(search_term, count: 0)[:suggested_queries]

        check = SuggestionCheck.new(
          search_term: search_term,
          expected_result: expected_result,
          suggested_query: suggested_queries.first
        )

        check.log_result
        calculator.add(check.result)
      end

      calculator
    end

    private

    def parsed_checks
      CSV.parse(@test_data_file, headers: true).map do |row|
        [row['Search term'], row['Ideal suggestion']]
      end
    end
  end
end
