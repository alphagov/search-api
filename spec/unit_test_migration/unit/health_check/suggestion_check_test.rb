require_relative "../../test_helper"
require "health_check/logging_config"
require "health_check/suggestion_check"
Logging.logger.root.appenders = nil

module HealthCheck
  class SuggestionCheckTest < ShouldaUnitTestCase
    context "#success?" do
      should "be true when the result and query match" do
        check = SuggestionCheck.new(expected_result: 'x', suggested_query: 'x')

        assert check.success?
      end

      should "be false when the result and query do not match" do
        check = SuggestionCheck.new(expected_result: 'A', suggested_query: 'B')

        refute check.success?
      end

      should "accept lowercase expected results" do
        check = SuggestionCheck.new(expected_result: 'A', suggested_query: 'a')

        assert check.success?
      end

      should "accept empty results" do
        check = SuggestionCheck.new(expected_result: '', suggested_query: nil)

        assert check.success?
      end
    end
  end
end
