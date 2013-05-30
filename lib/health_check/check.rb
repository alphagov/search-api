Check = Struct.new(:search_term, :imperative, :path, :minimum_rank, :weight)
Result = Struct.new(:success, :score, :possible_score)

class Check
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
    found_index = search_results.index { |url|
      URI.parse(url).path == path
    }

    found_in_limit = found_index && found_index < minimum_rank
    success = !!(positive_check? ? found_in_limit : ! found_in_limit)

    marker = "[#{weight}-POINT]"
    if found_index
      expectation = positive_check? ? "<= #{minimum_rank}" : "> #{minimum_rank}"
      message = "#{marker} Found '#{path}' for '#{search_term}' in position #{found_index + 1} (expected #{expectation})"
      if success
        logger.pass(message)
      else
        logger.fail(message)
      end
    else
      logger.fail("#{marker} Didn't find '#{path}' in results for '#{search_term}'")
    end

    score = success ? weight : 0
    Result.new(success, score, weight)
  end

  private
    def logger
      Logging.logger[self]
    end
end
