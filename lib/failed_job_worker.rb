require "pp"
require "sidekiq"

class FailedJobWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def logger
    Logging.logger[self]
  end

  sidekiq_options :queue => :failed

  def perform(job_info)
    # `job_info` is the same format at Sidekiq's job format, as serialised to
    # JSON and passed into Redis
    puts "Job failed"
    pp job_info
    # TODO: send out an notification email
  end
end
