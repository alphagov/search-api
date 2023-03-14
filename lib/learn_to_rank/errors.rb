module LearnToRank
  module Errors
    class LearnToRankError < StandardError; end

    class InvalidSageMakerResponse < LearnToRankError; end

    class InvalidContainerResponse < LearnToRankError; end

    def report_error(err, extra: {})
      GovukError.notify(err, extra:)
      log_error(err)
    end

    def log_error(err)
      Services.statsd_client.increment("learn_to_rank.errors.#{err.class}")
    end
  end
end
