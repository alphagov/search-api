class Batcher
  QUEUES_NAME = 'batcher_queues_name'
  MAX_QUEUE_LENGTH = 100

  def initialize(processor)
    @processor = processor
    @uuid = SecureRandom.uuid
  end

  def process(message)
    @process.process(message, worker: self)
  end

  def perform_async(*args)
    # store message on queue A
    queue_name = current_queue_name
    redis.rpush(current_queue_name, args.to_json)

    # check if count of message on the queue is greater than X
    if redis.llen(queue_name) >= MAX_QUEUE_LENGTH || after_timeout?(queue_name)
      process_queue(queue_name)
    end
  end

  def process_queue(queue_name)
    processed = false
    entrants_list = "#{queue_name}-entrant"

    # remove it from the queue_name list
    redis.lrem(queue_name_list, 0, queue_name)
    # add myself as an entrant
    redis.rpush(entrants_list, @uuid)

    # check if I am the winner
    if redis.lindex(entrants_list, 0) == @uuid
      # process message on queue A in bulk to the processor
      batched_data = redis.lrange(queue_name).map { |d| JSON.parse(d) }

      @processor.process(batch: batched_data)
      processed = true

      # delete the queue so that it isn't left on redis
      redis.del(queue_name)
    end

    # remove self from the entrants - assuming the winner will be the last to be removed
    redis.lrem(entrants_list, 0, @uuid)
    # remove the entrants list
    redis.del(entrants_list) if redis.llen(entrants_list) == 0
  rescue Exception
    # push the queue_name back onto the list of queue names so we can try and process it again
    # in the event of any errors
    redis.lpush(queue_name_list, queue_name) unless processed
    raise
  end

  def current_queue_name
    queue_name = redis.lget(queue_name_list, 0)
    return queue_name if queue_name
    redis.rpush(queue_name_list, "#{QUEUES_NAME}-#{processor.class}-#{SecureRandom.uuid}")
    redis.lindex(queue_name_list, 0)
  end

  def queue_name_list
    "#{QUEUES_NAME}-#{processor.class}"
  end

  def after_timeout?(queue_name)
    expiry = rdis.get("#{queue_name}-expiry")
    if expiry && Time.at(expiry)
  end

  def redis
    Sidekiq.redis
  end
end
