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
      @overall_calculator = Calculator.new
      @tag_calculators = {}
      @word_count_calculators = {}
      @file_output = produce_report ? SearchCheckReport.new : File.open(File::NULL, 'w')
    end

    def run!
      Logging.logger[self].info("Connecting to #{@search_client}")

      checks.each do |check|
        search_results = search_client.search(check.search_term)[:results]
        check_result = check.result(search_results)
        check_result.write_to_log
        @file_output << check_result
        overall_calculator.add(check_result)

        check.tags.each do |tag|
          tag_calculators[tag] ||= Calculator.new
          tag_calculators[tag].add(check_result)
        end

        word_count = check.search_term.split.size
        word_count_calculators[word_count] ||= Calculator.new
        word_count_calculators[word_count].add(check_result)
      end
    end

    def print_summary
      tag_calculators.sort.each do |tag, tag_calculator|
        tag_calculator.summarise("#{tag} score")
      end

      word_count_calculators.sort.each do |word_count, calculator|
        calculator.summarise("score for #{word_count}-word queries")
      end

      overall_calculator.summarise
    end

  private
    attr_reader :overall_calculator, :tag_calculators, :word_count_calculators

    def checks
      CheckFileParser.new(@test_data_file).checks.sort { |a, b| b.weight <=> a.weight }
    end
  end
end
