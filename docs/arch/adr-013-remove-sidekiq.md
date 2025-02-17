# Decision record: remove use of Sidekiq from indexing process

## Context

Currently, when Search API consumes a message from Publishing API regarding a document that needs indexing, it dumps the entire message payload (often > 20KB of JSON) into Redis for Sidekiq to process.

This was done for the reasons described in [ADR-001](./adr-001-use-of-both-rabbitmq-and-sidekiq-queues.md). However, this also limits our ability to handle large republishing jobs, because our Redis instance needs to be large (approx. 1GB of Redis memory per 50,000 documents republished). This could be an issue if, for example, we retroactively add a new searchable field to a heavily used document type. It is currently blocking the migration of Whitehall to use the govuk index.

[ADR-001](./adr-001-use-of-both-rabbitmq-and-sidekiq-queues.md) offered three features offered by Sidekiq as justification for using it to process RabbitMQ messages, rather than processing them directly.

1. Safe concurrency
2. Retries
3. Dead job handling

We ought to ensure that we can either provide parity with these features without Sidekiq, or to provide evidence that we don't need them.

## Safe Concurrency

RabbitMQ guarantees at-least-once delivery and does not guarantee message order, so we need to be careful that we don't override a document with stale data.

As noted in [ADR-002](./adr-002-handle-race-conditions-in-govuk-index.md), Elasticsearch supports external versioning of documents. All document payloads sent to the govuk indexes are versioned appropriately, except for in the case of deletion requests. This does not appear to be the case for the government index. Using Sidekiq will not provide any additional safety.

Presently the RabbitMQ queue consumer only runs a single worker thread for each process. At time of writing, Kubernetes is configured to run two replicas of the Search API worker pod at present, so there are two processes running. However, we can increase the number of worker threads using the option defined on the [GOVUK Message Consumer](https://github.com/alphagov/govuk_message_queue_consumer/blob/f2d9d4946f9283041fc19870c4a913ee272b5579/lib/govuk_message_queue_consumer/consumer.rb#L25). We could increase this to match the Sidekiq thread count, which is 3 by default.

## Retries

We can effectively retry messages by "nack"-ing the RabbitMQ message if the Elasticsearch indexing request fails. If it receives a "nack" for the message, RabbitMQ will repeat the delivery. However, we may find that this does not give time for the issue to be resolved, and that we therefore need to employ a backoff strategy for the retry. This would require us to store the number of retries for each message and introduce a delay to the process (i.e. wait for a period of time before responding with a "nack", without blocking the thread). Sidekiq backs off its retries out of the box.

It is worth noting that [Search API v2 does not nack messages it is unable to process](https://github.com/alphagov/search-api-v2/blob/2965eca51e87be68a4242e53d5220b254be555eb/app/message_processors/publishing_api_message_processor.rb#L34). However, it does retry its downstream request to index documents three times with a three-second delay between each try. If those retries all fail, it logs an error that the development team would need to investigate. We could take the same approach for Search API v1 if that is considered acceptable, but the version of the Elasticsearch gem that we're using does not support delayed retries.

## Dead Job Handling

RabbitMQ allows for the creation of a dead letter exchange for collecting messages that have been rejected by the consumer, or that have expired. There is no such exchange configured for the Search API queues. Sidekiq provides dead letter handling out of the box.

If we took the approach outlined in the [retries](#retries) section above of just logging an error if the Elasticsearch request fails, then we would not need to be concerned about dead letters.

# Decision

Index the message directly from the RabbitMQ message processing code.


