module HealthCheck
  class Calculator
    attr_reader :success_count, :total_count, :score, :possible_score

    def initialize(success_count=0, total_count=0, score=0, possible_score=0, options = {})
      @success_count = success_count
      @total_count = total_count
      @score = score
      @possible_score = possible_score
      @logger = options[:logger] || Logging.logger[self]
    end

    def add(result)
      @total_count += 1
      @possible_score += result.possible_score
      @success_count += 1 if result.success
      @score += result.score
    end

    def summarise(score_name = "Score")
      score_percentage = @score.to_f / @possible_score * 100
      @logger.info("#{score_name}: #{@score}/#{@possible_score} (#{format('%.2f', score_percentage)}%)")
      @logger.info("#{@success_count} of #{@total_count} succeeded")
    end

    def +(other)
      Calculator.new(self.success_count + other.success_count,
                     self.total_count + other.total_count,
                     self.score + other.score,
                     self.possible_score + other.possible_score)
    end

  end
end