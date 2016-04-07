namespace :message_queue do
  desc "Index documents that are published to the publishing-api"
  task :index_documents_from_publishing_api do
    # The following environment variables need to be set
    # RABBITMQ_HOSTS
    # RABBITMQ_VHOST
    # RABBITMQ_USER
    # RABBITMQ_PASSWORD

    # Load Airbrake to make govuk_message_queue_consumer send error notifications.
    require 'airbrake'
    require 'govuk_message_queue_consumer'
    require 'indexer/index_documents'
    require 'statsd'

    statsd_client = Statsd.new
    statsd_client.namespace = "govuk.app.rummager"

    GovukMessageQueueConsumer::Consumer.new(
      queue_name: "rummager_to_be_indexed",
      exchange_name: "published_documents",
      processor: Indexer::IndexDocuments.new,
      statsd_client: statsd_client,

      # Only listen to "links" updates, which the publishing-api sends after
      # something updates the links hash.
      routing_key: '*.links',
    ).run
  end
end
