class Batcher
  def initialize(processor)
    @processor = processor
  end

  def process(message)
    @process.process(message, worker: self)
  end

  def perform_async(*args)
    queue = Queue.new(@procesor)
    queue.add_job(args)

    if queue.batch_ready_for_processing?
      processed = false
      begin
        queue.close

        wait_for_other_workers
        processed = process(queue)
      rescue Exception => e
        queue.restore unless processed

      end
    end

  end

  def process(queue)
    processed = false
    entrant = Entrant.new(queue.queue_name)

    if entrant.i_should_process_the_queue?
      @processor.process(batch: queue.data)
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
      # TODO: check if queue_with name is in the list first
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

    def after_timeout?
      # expiry = rdis.get("#{queue_name}-expiry")
      # expiry && Time.at(expiry) < Time.now.to_i
      false
    end
  end
end
