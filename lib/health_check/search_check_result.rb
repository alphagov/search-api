module HealthCheck
  class SearchCheckResult
    def self.build(check:, search_results:)
      new(check: check, search_results: search_results).build
    end

    def initialize(check:, search_results:)
      @check = check
      @search_results = search_results
    end

    def build
      log_the_result
      self
    end

    def log_the_result
      logging_output = [path, search_term, position_found, expectation].join(',')
      if success
        logger.pass logging_output
      else
        logger.fail logging_output
      end
    end

    def success_label
      @success_label ||= success ? "PASS" : "FAIL"
    end

    def found_label
      @found_label ||= found_index ? "FOUND" : "NOT FOUND"
    end

    def position_found
      @position_found ||= found_index ? found_index + 1 : 0
    end

    def expectation
      @expectation ||= @check.positive_imperative? ? "<= #{minimum_rank}" : "> #{minimum_rank}"
    end

    def path
      @check.path
    end

    def search_term
      @check.search_term
    end

    def minimum_rank
      @check.minimum_rank
    end

    def success
      if @check.positive_imperative?
        found_within_limit?
      else
        ! found_within_limit?
      end
    end

    def possible_score
      @check.weight
    end

    def score
      success ? possible_score : 0
    end

private

    def logger
      Logging.logger[self]
    end

    def found_index
      @search_results.index { |url| URI.parse(url).path == path }
    end

    def found_within_limit?
      found_index && found_index < @check.minimum_rank
    end
  end
end
