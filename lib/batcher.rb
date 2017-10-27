# Due to the initial setup for the rabbit processing library we
# have to do a couple of small hack so that we can overwrite the
# calls to make everything work.
#
# first we want to override the worker that is used by the processor
# but this is only set when the process method is called. To get around
# this we use the Batcher class to wrap the `processor` object, this
# allows us to rewite the process method and pass the worker class
# we want to use. Which is in this instance is the Batcher class again.
#
# We then want to use the Batcher class as a wrapper around the sidekiq
# processor, so here we implement the `perform_async` method. This is
# responsible for batching up the jobs and then calling the actual
# worker with jobs once it is ready.
class Batcher
  def initialize(processor:, worker:)
    @processor = processor
    @worker = worker
  end

  def process(message)
    @processer.process(message, worker: self)
  end

  def perform_async(*args)
    queue = Queue.new(@procesor)
    queue.add_job(args)

    if queue.batch_ready_for_processing?
      processed = false
      begin
        queue.close

        wait_for_other_workers
        processed = process_queue(queue)
      rescue Exception => e
        queue.restore unless processed

      end
    end
  end

  def process_queue(queue)
    processed = false
    entrant = Entrant.new(queue.queue_name)

    if entrant.i_should_process_the_queue?
      @worker.perform_async(batch: queue.data)
      processed = true

      queue.delete
      wait_for_other_workers
      entrant.delete
    end
  ensure
    processed
  end

private

  def wait_for_other_workers
    sleep 2
  end

  # This class is used to determine if this worker instance should
  # be responsible for processing the batched data. This is important
  # as we only want to process each batch once.
  class Entrant
    def initialize(queue_name)
      @entrants_list = "#{queue_name}:entrant"
      @uuid = SecureRandom.new
      redis.rpush(entrants_list, @uuid)
    end

    def i_should_process_the_queue?
      redis.lindex(@entrants_list, 0) == @uuid
    end

    def delete
      redis.del(@entrants_list)
    end

    private

    def redis
      Sidekiq.redis
    end
  end

  # Just a wrapper to help do all the queue related functionality and
  # hide the redis implementation as much as possible.
  class Queue
    QUEUES_NAME = 'batcher_queues_name'
    MAX_QUEUE_LENGTH = 100

    attr_reader :queue_name

    # as everythig is async there is a possibility of stuff getting left on redis and
    # not having been deleted this task is to do a cleanup and delete all items
    def self.cleanup

    end

    def initialize(processor)
      @processor = processor
      @queue_name = current_queue_name
      # ensure_queue_timeout
    end

    def add_job(args)
      redis.rpush(current_queue_name, args.to_json)
    end

    def batch_ready_for_processing?
      redis.llen(queue_name) >= MAX_QUEUE_LENGTH || after_timeout?
    end

    def close
      redis.lrem(queue_name_list, 0, @queue_name)
    end

    def data
      redis.lrange(queue_name).map { |d| JSON.parse(d) }
    end

    def delete
      redis.del(queue_name)
    end

    def restore
      # TODO: check if queue_with name is in the list first? as otherwise this
      # could result in a queue being processed twice.
      # also what happens if the redis connection is down while trying to perform
      # this task. Would that result in the queue being orphaned?
      redis.lpush(queue_name_list, queue_name)
    end

    private

    def current_queue_name
      queue_name = first_queue_name
      return queue_name if queue_name
      open_new_queue
      first_queue_name
    end

    def redis
      Sidekiq.redis
    end


    def first_queue_name
      redis.lget(queue_name_list, 0)
    end

    def open_new_queue
      redis.rpush(queue_name_list, "#{QUEUES_NAME}:#{processor.class}:#{SecureRandom.uuid}")
    end


    def queue_name_list
      "#{QUEUES_NAME}:#{@processor.class}"
    end

    # This is here to avoid an extensive delay before data is written due to low volumes
    # however this is a less than idea approach as it would still be possible for the
    # last processing of the night to be left waiting for the first edit of the following
    # day.
    #
    # This may be better solved by have a separate scheduled task that does a force check/write
    # of any data that has been sitting for longer than X.
    def after_timeout?
      # expiry = rdis.get("#{queue_name}-expiry")
      # expiry && Time.at(expiry) < Time.now.to_i
      false
    end
  end
end
