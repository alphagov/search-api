require_relative "../../test_helper"
require "health_check/logging_config"
require "health_check/check"
Logging.logger.root.appenders = nil

module HealthCheck
  class CheckTest < ShouldaUnitTestCase
    context "result" do
      should "return a Result" do
        check = Check.new("carmen", "should", "/a", 1, 200)
        search_results = ["https://www.gov.uk/a"]

        result = check.result(search_results)

        assert_equal true, result.success
        assert_equal 200, result.score
        assert_equal 200, result.possible_score
      end

      context "desired result is outside of the desired ranking" do
        should "return a failure Result" do
          check = Check.new("carmen", "should", "/a", 1, 200)
          search_results = ["https://www.gov.uk/b", "https://www.gov.uk/a"]

          result = check.result(search_results)

          assert_equal false, result.success
          assert_equal 0, result.score
          assert_equal 200, result.possible_score
        end
      end

      context "desired result isn't in the results" do
        should "return a failure Result" do
          check = Check.new("carmen", "should", "/a", 1, 200)
          search_results = ["https://www.gov.uk/b", "https://www.gov.uk/a"]

          result = check.result(search_results)

          assert_equal false, result.success
          assert_equal 0, result.score
          assert_equal 200, result.possible_score
        end
      end
    end
  end
end