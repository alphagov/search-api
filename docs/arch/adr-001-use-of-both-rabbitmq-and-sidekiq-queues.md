# Decision record: use of both RabbitMQ (bunny) and Redis (Sidekiq) queuing systems

## Context

In order to simplify the search infrastructure we are moving to using the publishing API
as the source of data. This allows us to reduce the amount of code duplication across
projects, as currently each publishing app has to implement a write interface into rummager.

We expect this will give us a number of improvements, including:

* rebuild the search index more easily
* reduce the load on the publishing API - rummager currently needs to retrieve tagging data
  from the publishing API when it indexes documents

The publishing API currently uses rabbit MQ to tell downstream apps that a new publishing
event has occurred, with the key specifying the publishing app and the publishing event
type.

Rummager currently processes `link` events from the rabbit MQ stream, this works by reading
the message off the rabbitMQ stream, doing a small amount of manipulation and then creating
a Sidekiq worker task to perform the data update.

When processing messages off the queue it is important that the process can provide the following features:

* Concurrency
* Failure/Queue side tracking
* Retry logic


## Decision

We initially looked at two options, either reading the data from the rabbit MQ stream and
processing inplace, or writing the message to a Sidekiq worker and then have it perform
the required processing.

While it is possible to implement all the above features using just the rabbit MQ system
there is currently no simple way to do this and all the logic would need to be manually coded.

For this reason we have opted to use the Sidekiq queue library alongside rabbit MQ as it provides
all the functionality that we require out of the box in a fully tested and mantained system.

This also means we are not locked into rabbit MQ as the distribution system of publishing API
messages, this is esspecially import as Tijmen suggested this may be changed in the future.

## Status

Accepted.

## Consequences

This means we have additional points of failure in the system, as we are reading from one queue
and writing to second one. This is especially important when debugging and we have a clear
diagram for the data flow through the system as well as a documented way to determine the status
of a message within the system.

In addition to this it is important to differentiate the different components and ensure that
new developers are clear which gems/libraries are associated with which queuing system.
