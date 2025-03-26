# This class should be used as a wrapper around GovukMessageQueueConsumer::Message
# whenever we use an exchange that uses a dead letter exchange (dlx) as a retry
# mechanism. Using a dlx in this way means sending counter intuitive responses to
# RabbitMQ. Where an ack is the approach to mark a job as completed AND to mark a
# job as failed, whereas discard actually signifies that we're going to retry the job.

# You should only use this class if you're planning to retry via a dlx otherwise
# it'll be very confusing!

class RetryableQueueMessage
  delegate :payload, :headers, :status, :delivery_info, to: :queue_message

  def initialize(queue_message)
    @queue_message = queue_message
  end

  def done
    queue_message.ack
  end

  def retry
    queue_message.discard
  end

  def retries
    # headers doesn't return a hash but a hash like object (Bunny::MessageProperties)
    deaths = (headers[:headers] || {}).fetch("x-death", [])
    # we expect each retry to flag as two deaths (1 for the initial discard,
    # the other for a timeout to delay the retry)
    deaths.sum { |d| d["count"] } / 2
  end

private

  attr_reader :queue_message
end
