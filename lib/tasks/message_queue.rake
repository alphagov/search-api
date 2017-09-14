# The following environment variables need to be set
# RABBITMQ_HOSTS
# RABBITMQ_VHOST
# RABBITMQ_USER
# RABBITMQ_PASSWORD
require 'rummager'

namespace :message_queue do
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
