require "uri"
require "health_check/local_search_client"
require "health_check/check_file_parser"
require "health_check/calculator"

module HealthCheck
  class Checker

    attr_reader :search_client

    def initialize(options = {})
      @test_data = options[:test_data]

      @search_client = options[:search_client]
    end

    def run!
      Logging.logger[self].info("Connecting to #{@search_client.to_s}")

      checks.each do |check|
        search_results = search_client.search(check.search_term)
        result = check.result(search_results)
        calculator.add(result)
      end
      calculator
    end

    private
      def checks
        CheckFileParser.new(File.open(@test_data)).checks.sort { |a,b| b.weight <=> a.weight }
      end

      def calculator
        @_calculator ||= Calculator.new
      end
  end
end