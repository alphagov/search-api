require "health_check/result"

module HealthCheck
  class SearchCheck < Struct.new(:search_term, :imperative, :path, :minimum_rank, :weight)
    def valid_imperative?
      ["should", "should not"].include?(imperative)
    end

    def valid_path?
      !path.nil? && !path.empty? && path.start_with?("/")
    end

    def valid_search_term?
      !search_term.nil? && !search_term.empty?
    end

    def valid_weight?
      weight > 0
    end

    def valid?
       valid_imperative? && valid_path? && valid_search_term? && valid_weight?
    end

    def positive_check?
      imperative == "should"
    end

    def result(search_results)
      found_index = search_results.index { |url| URI.parse(url).path == path }
      found_in_limit = found_index && found_index < minimum_rank
      success = !!(positive_check? ? found_in_limit : ! found_in_limit)

      position_found = found_index ? found_index + 1 : 0
      found_label = found_index ? "FOUND" : "NOT FOUND"
      expectation = positive_check? ? "<= #{minimum_rank}" : "> #{minimum_rank}"
      success_label = success ? "PASS" : "FAIL"

      logging_output = [path, search_term, position_found, expectation].join(',')
      if success
        logger.pass logging_output
      else
        logger.fail logging_output
      end

      score = success ? weight : 0
      Result.new(
        success, score, weight, success_label, found_label,
        path, search_term, position_found, expectation
      )
    end

    private
      def logger
        Logging.logger[self]
      end
  end
end
