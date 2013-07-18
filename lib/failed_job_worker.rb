require "stringio"
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
    mailer = settings.mailer
    unless mailer
      logger.warn "No mailer configured for failed job: discarding"
      logger.debug job_info
      return
    end

    message_body = StringIO.new
    message_body << introduction
    message_body << "\n\n"
    PP.pp(job_info, message_body)
    mailer.send_email("Job failure", message_body.string)
  end

private
  def introduction
    "The following job failed submission to elasticsearch:"
  end
end
