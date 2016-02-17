require "health_check/suggestion_check_result"

module HealthCheck
  class SuggestionCheck
    attr_reader :search_term, :expected_result, :suggested_query

    def initialize(args = {})
      @search_term = args[:search_term]
      @expected_result = args[:expected_result]
      @suggested_query = args[:suggested_query]
    end

    def log_result
      if success?
        logger.pass(message)
      else
        logger.fail(message)
      end
    end

    # Create a SuggestionCheckResult with score of 0 or 1 out of 1. It's possible to use the
    # `score and `possible_score` to add weighting to the scoring. For example
    # to give a test a "3 out of 5" score.
    def result
      score = success? ? 1 : 0
      possible_score = 1
      SuggestionCheckResult.new(success?, score, possible_score)
    end

    # Compare the expected result and suggested query. When the expected result
    # is empty/nil, the suggested query should also be empty or nil?
    def success?
      suggested_query.to_s.downcase == expected_result.to_s.downcase
    end

  private

    def message
      if success?
        if expected_result_empty?
          "'#{search_term}' has no corrections"
        else
          "'#{search_term}' corrects to '#{expected_result}'"
        end
      else
        if expected_result_empty?
          "'#{search_term}' should not be corrected but corrects to '#{suggested_query}'"
        else
          "'#{search_term}' should be be corrected to '#{expected_result}' but #{suggested_query.nil? ? 'does not correct' : "corrects to '#{suggested_query}'"}"
        end
      end
    end

    def expected_result_empty?
      expected_result.nil? || expected_result == ''
    end

    def logger
      Logging.logger[self]
    end
  end
end
