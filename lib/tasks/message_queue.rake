# The following environment variables need to be set
# RABBITMQ_HOSTS
# RABBITMQ_VHOST
# RABBITMQ_USER
# RABBITMQ_PASSWORD
require 'rummager'

namespace :message_queue do
  desc "Create the queues that Rummager uses with Rabbit MQ"
  task :create_queues do
    config = GovukMessageQueueConsumer::RabbitMQConfig.from_environment(ENV)
    bunny = Bunny.new(config)

    channel = bunny.start.create_channel
    exch = Bunny::Exchange.new(channel, :topic, "published_documents")
    channel.queue("rummager_to_be_indexed").bind(exch, routing_key: "*.links")
    channel.queue("rummager_bulk_reindex").bind(exch, routing_key: "*.bulk.reindex")
    channel.queue("rummager_govuk_index").bind(exch, routing_key: "*.*")
  end

  desc "Index documents that are published to the publishing-api"
  task :listen_to_publishing_queue do
    GovukMessageQueueConsumer::Consumer.new(
      queue_name: "rummager_to_be_indexed",
      processor: Indexer::MessageProcessor.new,
      statsd_client: Services.statsd_client,
    ).run
  end

  desc "Gets data from RabbitMQ and insert into govuk index"
  task :insert_data_into_govuk do
    GovukMessageQueueConsumer::Consumer.new(
      queue_name: "rummager_govuk_index",
      processor: GovukIndex::PublishingEventProcessor.new,
      statsd_client: Services.statsd_client,
    ).run
  end

  desc "Gets data from RabbitMQ and insert into govuk index (bulk reindex queue)"
  task :bulk_insert_data_into_govuk do
    GovukMessageQueueConsumer::Consumer.new(
      queue_name: "rummager_bulk_reindex",
      processor: GovukIndex::PublishingEventProcessor.new,
      statsd_client: Services.statsd_client,
    ).run
  end
end
