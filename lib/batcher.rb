class Batcher
  QUEUES_NAME = 'batcher_queues_name'

  def initialize(processor)
    @processor = processor
  end

  def process(message)
    # store message on queue A
    queue_name = current_queue_name
    if redis.llen(queue_name) >
    redis.rpush("#{QUEUES_NAME}-#{processor.class}", "#{QUEUES_NAME}-#{processor.class}-#{SecureRandom.uuid}")

    # check if count of message on the queue is greater than X

    # update the storage queue to Queue B if we are the winner

    # process message on queue A in bulk to the processor
  end

  def current_queue_name
    queue_name = redis.lget("#{QUEUES_NAME}-#{processor.class}", 0)
    return queue_name if queue_name
    redis.rpush("#{QUEUES_NAME}-#{processor.class}", "#{QUEUES_NAME}-#{processor.class}-#{SecureRandom.uuid}")
    redis.lget("#{QUEUES_NAME}-#{processor.class}", 0)
  end

  def redis
    Sidekiq.redis
  end
end
