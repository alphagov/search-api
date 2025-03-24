require "rummager"

namespace :message_queue do
  desc "Create the queues that Rummager uses with Rabbit MQ"
  task :create_queues do
    bunny = Bunny.new

    channel = bunny.start.create_channel
    exch = Bunny::Exchange.new(channel, :topic, "published_documents")

    search_api_to_be_indexed_retry_dlx = channel.fanout("search_api_to_be_indexed_retry_dlx")
    search_api_to_be_indexed_discarded_dlx = channel.fanout("search_api_to_be_indexed_discarded_dlx")

    channel
      .queue("search_api_to_be_indexed", arguments: { "x-dead-letter-exchange" => search_api_to_be_indexed_retry_dlx.name })
      .bind(exch, routing_key: "*.links")
    # messages are queued on search_api_to_be_indexed_discarded_dlx for 30s before their
    # ttl completes then are routed to the search_api_to_be_indexed_retry_dlx
    channel.queue("search_api_to_be_indexed_wait_to_retry",
                  arguments: { "x-dead-letter-exchange" => search_api_to_be_indexed_discarded_dlx.name, "x-message-ttl" => 30 * 1000 })
           .bind(search_api_to_be_indexed_retry_dlx)

    # messages on the search_api_to_be_indexed_discarded_dlx are routed back to the original queue
    channel.queue("search_api_to_be_indexed").bind(search_api_to_be_indexed_discarded_dlx)

    channel.queue("search_api_bulk_reindex").bind(exch, routing_key: "*.bulk.reindex")
    channel.queue("search_api_govuk_index").bind(exch, routing_key: "*.*")
  end

  desc "Index documents that are published to the publishing-api"
  task :listen_to_publishing_queue do
    logger = Logging.logger[Indexer::MessageProcessor]

    GovukMessageQueueConsumer::Consumer.new(
      queue_name: "search_api_to_be_indexed",
      processor: Indexer::MessageProcessor.new,
      logger:,
      worker_threads: 10,
      prefetch: 10,
    ).run
  end

  desc "Gets data from RabbitMQ and insert into govuk index"
  task :insert_data_into_govuk do
    GovukMessageQueueConsumer::Consumer.new(
      queue_name: "search_api_govuk_index",
      processor: GovukIndex::PublishingEventProcessor.new,
    ).run
  end

  desc "Gets data from RabbitMQ and insert into govuk index (bulk reindex queue)"
  task :bulk_insert_data_into_govuk do
    GovukMessageQueueConsumer::Consumer.new(
      queue_name: "search_api_bulk_reindex",
      processor: GovukIndex::PublishingEventProcessor.new,
    ).run
  end
end
