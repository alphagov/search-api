require "health_check/search_check_result"

module HealthCheck
  class SearchCheck < Struct.new(:search_term, :imperative, :path, :minimum_rank, :weight)
    def valid_imperative?
      ["should", "should not"].include?(imperative)
    end

    def positive_imperative?
      imperative == "should"
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

    def result(search_results)
      SearchCheckResult.new(check: self, search_results: search_results).build
    end
  end
end
