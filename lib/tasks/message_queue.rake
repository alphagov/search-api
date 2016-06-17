namespace :message_queue do
  desc "Index documents that are published to the publishing-api"
  task :listen_to_publishing_queue do
    # The following environment variables need to be set
    # RABBITMQ_HOSTS
    # RABBITMQ_VHOST
    # RABBITMQ_USER
    # RABBITMQ_PASSWORD

    # Load Airbrake to make govuk_message_queue_consumer send error notifications.
    require 'airbrake'
    require 'govuk_message_queue_consumer'
    require 'indexer/message_processor'
    require 'statsd'

    statsd_client = Statsd.new
    statsd_client.namespace = "govuk.app.rummager"

    puts "Starting message queue consumer"

    GovukMessageQueueConsumer::Consumer.new(
      queue_name: "rummager_to_be_indexed",
      processor: Indexer::MessageProcessor.new(statsd_client),
      statsd_client: statsd_client,
    ).run
  end
end
