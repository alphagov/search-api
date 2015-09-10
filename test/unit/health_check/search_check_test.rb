require_relative "../../test_helper"
require "health_check/logging_config"
require "health_check/search_check"
Logging.logger.root.appenders = nil

module HealthCheck
  class SearchCheckTest < ShouldaUnitTestCase
  end
end
