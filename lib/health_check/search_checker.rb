require "uri"
require "health_check/check_file_parser"
require "health_check/calculator"
require "health_check/search_check_report"

module HealthCheck
  class SearchChecker
    attr_reader :search_client

    def initialize(search_client:, test_data:, produce_report: true)
      @test_data_file = test_data
      @search_client = search_client
      @file_output = produce_report ? SearchCheckReport.new : File.open(File::NULL, 'w')
    end

    def run!
      Logging.logger[self].info("Connecting to #{@search_client.to_s}")

      checks.each do |check|
        search_results = search_client.search(check.search_term)[:results]
        check_result = check.result(search_results)
        @file_output << check_result
        calculator.add(check_result)
      end

      calculator
    end

    private
      def checks
        CheckFileParser.new(@test_data_file).checks.sort { |a,b| b.weight <=> a.weight }
      end

      def calculator
        @_calculator ||= Calculator.new
      end
  end
end
