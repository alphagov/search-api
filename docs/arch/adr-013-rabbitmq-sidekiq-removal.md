# Decision record: Removing Sidekiq from RabbitMQ queue consumers

**Date:** 2025-04-07

This supersedes [ADR-001][].

## Context
In [ADR-001] a decision was recorded that queue messages from RabbitMQ would be then pushed onto a Sidekiq queue for handling. We have decided to revisit this decision in light of a number of problems:

- The data in an individual queue message is often large and bulk pushing of data by Publishing API is relatively common; this had made it hard to establish the appropriate size for Redis as it needs substantial memory to handle a bulk republishing. This has contributed to two incidents.
- At the time of the initial decision the message queue was processed by a single thread so had very low concurrency. There are now concurrency features provided by govuk_message_queue_consumer so this can be scaled in a similar way to Sidekiq.
- A confusing architecture that is inconsistent with other GOV.UK apps. Other GOV.UK apps that listen to queues process them directly, which reduces what you need to understand to monitor queue statuses. By combining RabbitMQ and Sidekiq it is much harder to understand the actual processing of messages from the message queue, with data in multiple places interlinked with other Sidekiq processing.


## Decision
We have decided to remove Sidekiq from the RabbitMQ queue consumer code, and instead leverage the concurrency features of the [govuk_message_queue_consumer][] gem.

## Status
Approved

## Consequences
One useful feature of Sidekiq is that it automatically handles retries. When a job fails, Sidekiq will catch the error and try again multiple times with exponential backoff. The tradeoff we've made here is that we've now had to write code to do this ourselves in the queue consumers, which involves a bit of extra complexity both with regards to the code in this repo and the setup of RabbitMQ. RabbitMQ provides no other retry system than a basic automatic retry straight away without extra queue configuration.

The flow is as follows:

* We catch an exception within the consumer code
* We call `discard` on the message which tells RabbitMQ to send the message to a configured dead letter exchange (DLX)
* Messages on that DLX have a TTL (time to live) set. After this time they'll be routed back to the original queue and picked up again by the consumer
* The consumer monitors the retry count and if it exceeds a certain threshold, we discard the message without retrying and notify Sentry

We've now spread the complexity of retries over multiple places (this app and the RabbitMQ infrastructure). But messages are now only processed as fast as they can be consumed, rather than moving them from RabbitMQ to Sidekiq.

[ADR-001]: /docs/arch/adr-001-use-of-both-rabbitmq-and-sidekiq-queues.md
[govuk_message_queue_consumer]: https://github.com/alphagov/govuk_message_queue_consumer
