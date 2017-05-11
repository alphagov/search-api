require "health_check/suggestion_check_result"

module HealthCheck
  class SuggestionCheck
    attr_reader :search_term, :expected_result, :suggested_query, :tags

    def initialize(search_term: nil, expected_result: nil, suggested_query: nil, tags: [])
      @search_term = search_term
      @expected_result = expected_result
      @suggested_query = suggested_query
      @tags = tags
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
      SuggestionCheckResult.new(success?, score, possible_score, tags)
    end

    # Compare the expected result and suggested query. When the expected result
    # is empty/nil, the suggested query should also be empty or nil?
    def success?
      suggested_query.to_s.casecmp(expected_result.to_s.downcase).zero?
    end

  private

    def message
      if success?
        if expected_result_empty?
          "'#{search_term}' has no corrections"
        else
          "'#{search_term}' corrects to '#{expected_result}'"
        end
      elsif expected_result_empty?
        "'#{search_term}' should not be corrected but corrects to '#{suggested_query}'"
      else
        "'#{search_term}' should be corrected to '#{expected_result}' but #{suggested_query.nil? ? 'does not correct' : "corrects to '#{suggested_query}'"}"
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
