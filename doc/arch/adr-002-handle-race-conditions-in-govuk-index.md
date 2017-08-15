# Decision record: use versioning to handle race conditions when updating the govuk index

## Context

We are in the process of creating a new 'govuk' index to replace the existing
mainstream, government and detailed indexes. The new index will be populated by
rummager using publishing and unpublishing event messages pulled from a queue
controlled by the publishing API.

Rummager cannot rely on messages from the queue being processed in the order
that they were generated. This means that either rummager should handle edge
cases such as these or we will need to accept the consequences:

- A document is published twice in quick succession. The second publishing event
  arrives in rummager first. The later, stale message should not overwrite the
  more recent data in the index.
- A document is unpublished and then immediately republished. The republishing
  message is processed first. The later, stale unpublishing message should be
  ignored and the published document should remain in the search index.
- A document is published and then immediately unpublished. The unpublishing
  event is processed first. The later, stale publishing message should not
  re-add the document to the search index. It should remain unpublished.

## Decision

### Use Elasticsearch's external versioning

Elasticsearch supports [external versioning][es-versioning] for documents. This
means that each document includes a version number from an external system,
which in our case is the publishing event number from the publishing API.

When the version number is set, Elasticsearch uses optimistic locking to ensure
that a document is never updated or deleted if the new version number is less
than or equal to the existing version number.

This will take care of some of the edge cases:

- If two publishing events arrive out of order, the second stale event will be
  ignored because the version number is lower. Result: the document in the index
  ends up in the expected state, which is the most recent version.
- If a republishing message arrives before an earlier unpublishing message, the
  unpublishing will be ignored because its version number is lower. Result: the
  document remains in the index as expected.

[es-versioning]: https://www.elastic.co/blog/elasticsearch-versioning-support

### Delete unpublished documents

The simplest way to handle an unpublishing event is to delete the document from
the index. Unfortunately, this could lead to a race condition which will leave
the index in a bad state:

- If a document is published and then immediately unpublished but the
  unpublished message arrives first, it will initially be deleted from the
  index. But when the stale republishing message arrives, it will incorrectly
  recreate the document. Result: the document remains in the search index
  despite being unpublished.

We considered handling this by storing unpublished documents as tombstone
records. These would be temporary: they would be cleaned up by reindexing tasks,
but would be present for long enough to prevent this race condition:

- The unpublishing message arrives first and saves the document with an
  'unpublished' flag. The stale republishing message then arrives, but the
  message is ignored because its version is lower than the unpublishing message.
  Result: the tombstone record remains in the search index as expected.

We have decided to postpone the [implementation of
tombstone records][tombstone-records-card] until we have time to work on it. In
the meantime, this race condition may occur, but the sequence of events leading
to it are expected to be rare.

[tombstone-records-card]: https://trello.com/c/ap5pQF5R/190-add-tombstone-records-for-deleted-documents

### Rely on reindexing to fix inconsistencies

We intend to schedule a regular reindexing job which will create a new index
from scratch using the latest version of the data from the publishing API.

This will fix any inconsistent documents caused by unhandled race conditions.

## Status

Accepted.

## Consequences

As described above, most race conditions should be handled correctly by the
versioning system, but race conditions in unpublishing may lead to occasional
unpublished documents appearing in the search index until the next time the
whole index is recreated.

This means that users might see the name and description of the unpublished page
in GOV.UK site search and in any relevant finders. If they were to click on the
link to the unpublished page they would see a 404 Not Found page or be
redirected to a different page, depending on how the page was unpublished.

If this did occur, the support team would have several options to remove the
page from the search index:
- Remove the document using a rake task in the publishing API which resends the
  unpublishing message
- Remove the document using the [search admin][search-admin] tool
- In non-urgent cases, wait for reindexing

[search-admin]: https://github.com/alphagov/search-admin
