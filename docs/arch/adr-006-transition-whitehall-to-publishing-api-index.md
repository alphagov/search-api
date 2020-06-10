# Decision record: Transition whitehall documents to a Publishing API derived search index

Date: 2017-12-21

## Definitions

Throughout this document, `format` refers to the Rummager field `format`, not the document type provided by Publishing API (`content_store_document_type`).

Every `content_store_document_type` is mapped to a single `format`.

## Context
Publishing applications used to directly communicate with rummager to index
documents, using the `/documents` HTTP API.

We've removed this integration for all publishing apps except for whitehall publisher.
The publishing API now notifies rummager of every update, using a RabbitMQ
message queue. Rummager responds to these messages by updating the `govuk`
index. This has allowed us to remove the old `mainstream` index, which contained
all sorts of documents beyond what we normally think of as "mainstream" content.
The `govuk` index can be rebuilt from scratch by resending the content
from publishing API.

See [ADR 006](adr-004-transition-mainstream-to-publishing-api-index.md) for more
details about moving mainstream content to the govuk index.

This leaves two indexes that are populated the old way: `government` and `detailed`.

`detailed` contains detailed guides and `government` contains everything else
published by Whitehall publisher.

We also have a separate worker (`publishing-queue-listener`) that listens to
`*.links` notifications from publishing API, and *updates* the old indexes
(but doesn't add any new content).

## Decision

We intend to get rid of the `government` and `detailed` indexes. Rummager
should index Whitehall Publisher documents into the `govuk` index.

All search indexing code should be removed from Whitehall Publisher.

The old indexing code should be removed from Rummager:

- Anything in `lib/indexer`
- The `publishing-queue-listener` worker

The [infrastructure to log indexing requests to disk](https://docs.publishing.service.gov.uk/manual/rummager-traffic-replay.html) can also be removed,
since data from the publishing API can be resent at any time.

## Consequences

There are over 200,000 documents published by Whitehall Publisher.

There is also a lot of information about content that isn't currently available to rummager. For example:

- The **state** of a document, based on archiving policy and content audits
- **Publishing history** details besides the `public_updated_at` value
- **Who** the content is applicable to or **where** it is relevant
- What **services** or **task lists** the content belongs to
- Entities mentioned in the text of the page (or its attachments), like **people**, **organisations**, **places**, **deadlines** and **forms**.

When all documents are indexed from the publishing API, we will be able to make better use of the available data to improve search,
because there will be a single indexing process that we can change easily.

This work is also a dependency for [running Rummager in the draft stack](https://github.com/alphagov/govuk-rfcs/pull/86), to support preview behaviour and draft taxonomies.

Combining all of the indexes into a single index will change the document frequency statistics, which affects how search results are scored.



## Action plan

### Copy over documents as-is and test
Before making any changes to Whitehall Publisher, we should copy all documents from the `government` and `detailed` indexes to the `govuk` index.

These documents will be filtered out of search results, but will have an indirect impact on scoring of other documents.

We can then run the search healthcheck to understand the impact of this. At this stage we may want to reevaluate how much each format gets boosted in the search query.

Once this is done, the `govuk` indexing process can be extended to Whitehall Publisher formats.

### Follow the process to move a document type to the new indexing process
See [new indexing process](https://github.com/alphagov/rummager/blob/master/docs/new-indexing-process.md)

 This process needs to be repeated for each document type or group of related document types.

### Delete the old indexes
Once every document type is done, check for missing documents and then remove the old indexes and indexing code.

See [example script for checking all documents are indexed correctly](https://github.com/alphagov/rummager/pull/1120).
