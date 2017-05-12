module HealthCheck
  class Calculator
    attr_reader :success_count, :total_count

    def initialize(success_count = 0, total_count = 0, logger: Logging.logger[self])
      @success_count = success_count
      @total_count = total_count
      @logger = logger
    end

    def add(result)
      @total_count += 1
      @success_count += 1 if result.success
    end

    def summarise(score_name = "Score")
      @logger.info("#{score_name}: #{@success_count} of #{@total_count} succeeded")
    end
  end
end
