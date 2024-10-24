require "rummager"

namespace :message_queue do
  desc "Create the queues that Rummager uses with Rabbit MQ"
  task :create_queues do
    bunny = Bunny.new

    channel = bunny.start.create_channel
    exch = Bunny::Exchange.new(channel, :topic, "published_documents")
    channel.queue("search_api_to_be_indexed").bind(exch, routing_key: "*.links")
    channel.queue("search_api_bulk_reindex").bind(exch, routing_key: "*.bulk.reindex")
    channel.queue("search_api_govuk_index").bind(exch, routing_key: "*.*")
    channel.queue("search_api_specialist_finder_index_documents").bind(exch, routing_key: "specialist_document.*")
    channel.queue("search_api_specialist_finder_index_finders").bind(exch, routing_key: "finder.*")
  end

  desc "Index documents that are published to the publishing-api"
  task :listen_to_publishing_queue do
    GovukMessageQueueConsumer::Consumer.new(
      queue_name: "search_api_to_be_indexed",
      processor: Indexer::MessageProcessor.new,
    ).run
  end

  desc "Gets data from RabbitMQ and insert into govuk index"
  task :insert_data_into_govuk do
    GovukMessageQueueConsumer::Consumer.new(
      queue_name: "search_api_govuk_index",
      processor: GovukIndex::PublishingEventProcessor.new,
    ).run
  end

  desc "Gets data from RabbitMQ and insert into specialist finder index"
  task :insert_data_into_specialist_finder do
    GovukMessageQueueConsumer::Consumer.new(
      queue_name: "search_api_specialist_finder_index_documents",
      processor: SpecialistFinderIndex::PublishingEventProcessor.new,
    ).run
    GovukMessageQueueConsumer::Consumer.new(
      queue_name: "search_api_specialist_finder_index_finders",
      processor: SpecialistFinderIndex::PublishingEventProcessor.new,
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
