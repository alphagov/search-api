require "govuk_app_config"
require "learn_to_rank/ranker_status"

module Healthcheck
  # This is a custom check that is called by GovukHealthcheck
  # See GovukHealthcheck (govuk_app_config/docs/healthchecks.md) for usage info
  class RerankerHealthcheck
    def name
      :reranker_healthcheck
    end

    def status
      reranker_status.healthy? ? :ok : :warning
    end

    def message
      reranker_status.healthy? ? "reranker is OK" : "reranker is unhealthy!"
    end

    def details
      reranker_status.healthy? ? {} : { extra: { errors: reranker_status.errors } }
    end

    def enabled?
      !%w(development).include? ENV["RACK_ENV"]
    end

  private

    def reranker_status
      @reranker_status ||= LearnToRank::RankerStatus.new
    end
  end
end
