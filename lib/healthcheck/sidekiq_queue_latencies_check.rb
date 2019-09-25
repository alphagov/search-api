require "govuk_app_config"

module Healthcheck
  # See GovukHealthcheck (govuk_app_config/docs/healthchecks.md) for usage info
  class SidekiqQueueLatenciesCheck < GovukHealthcheck::SidekiqQueueLatencyCheck
    def warning_threshold(queue:)
      # the warning threshold for a particular queue
      search_queue_thresholds[queue][:warning]
    end

    def critical_threshold(queue:)
      # the critical threshold for a particular queue
      search_queue_thresholds[queue][:critical]
    end

  private

    def search_queue_thresholds
      {
        "default" => {
          critical: 1.minute,
          warning: 30.seconds,
        },
        "bulk" => {
          critical: 30.minutes,
          warning: 5.minutes,
        }
      }
    end
  end
end
