require "rummager"

namespace :message_queue do
  desc "Create the queues that Rummager uses with Rabbit MQ"
  task :create_queues do
    bunny = Bunny.new

    channel = bunny.start.create_channel
    exch = Bunny::Exchange.new(channel, :topic, "published_documents")

    queues = [
      { name: "search_api_bulk_reindex", routing_key: "*.bulk.reindex" },
      { name: "search_api_govuk_index", routing_key: "*.*" },
    ]

    queues.each do |queue|
      name = queue[:name]
      routing_key = queue[:routing_key]

      retry_dlx = channel.fanout("#{name}_retry_dlx")
      discarded_dlx = channel.fanout("#{name}_discarded_dlx")

      # messages are queued on {queue}_discarded_dlx for 30s before their
      # ttl completes then are routed to the {queue}_retry_dlx
      channel
        .queue(
          "#{name}_wait_to_retry",
          durable: true,
          arguments: { "x-dead-letter-exchange" => discarded_dlx.name, "x-message-ttl" => 10 * 3000 },
        )
        .bind(retry_dlx)

      channel.queue(name, durable: true, arguments: { "x-dead-letter-exchange" => retry_dlx.name }).tap do |q|
        q.bind(exch, routing_key:)
        # messages on the {queue}_discarded_dlx are routed back to the original queue
        q.bind(discarded_dlx)
      end
    end
  end

  desc "Gets data from RabbitMQ and insert into govuk index"
  task :insert_data_into_govuk do
    logger = Logging.logger[GovukIndex::PublishingEventProcessor]

    GovukMessageQueueConsumer::Consumer.new(
      queue_name: "search_api_govuk_index",
      processor: GovukIndex::PublishingEventProcessor.new,
      logger:,
      worker_threads: 10,
      prefetch: 10,
    ).run
  end

  desc "Gets data from RabbitMQ and insert into govuk index (bulk reindex queue)"
  task :bulk_insert_data_into_govuk do
    logger = Logging.logger[GovukIndex::PublishingEventProcessor]

    GovukMessageQueueConsumer::Consumer.new(
      queue_name: "search_api_bulk_reindex",
      processor: GovukIndex::PublishingEventProcessor.new,
      logger:,
      worker_threads: 10,
      prefetch: 10,
    ).run
  end
end
