# Decision record: Transition mainstream formats to a Publishing API derived search index

Date: 2017-08-24

## Definitions

Throughout this document, `format` refers to the Rummager field `format`, not the document type provided by Publishing API (`content_store_document_type`).

Every `content_store_document_type` is mapped to a single `format`.

`mainstream` is used as an example of a search index we want to retire. This document should also apply to the `government` and `detailed` indexes.

## Context
### We're building a new search index using publishing API data
We're currently replacing the existing search indexes (`mainstream`, `government`, `detailed`) with a single index (`govuk`), which is derived from Publishing API.

The existing indexes are populated from [at least 10 different applications](https://docs.publishing.service.gov.uk/apps.html).

This change should improve the quality of the data our search system relies on:

- all formats are handled in a consistent manner
- we can update documents after any publishing event (publishing, withdrawing, unpublishing, tagging)
- it should be easier to rebuild if we need to revert to an old backup

### Lifecycle of our search indexes
Rumamger's search indexes are long lived, but content is regularly
updated to derive the `popularity` field from recent pageviews.
As of [ADR 003: Popularity updating without index locks](adr-003-popularity-updating-without-index-locks.md),
this uses updates, rather than rebuilding the search index every time.

There is a separate task in place to reindex the content currently in the search indexes with [zero downtime](https://www.elastic.co/guide/en/elasticsearch/guide/current/index-aliases.html).
This is something we need to do after adding new fields or otherwise changing
the Elasticsearch mappings, for those fields to work properly.

### Problems we're not addressing now

Neither of the above mechanisms add or remove documents from the search index, which means that:

- if an edition is ever published, and the search index doesn't get updated, it stays out of date until the next time the document is updated

- if an edition is unpublished without Rummager being notified, it stays in the search index forever

Long term, we'd like to be able to easily rebuild the whole `govuk` index from scratch, to avoid these kind of problems, but we aren't aiming to do this right now.

### Immediate needs

We need to be able to populate the `govuk` index with all the documents that
already exist, so we can start using this index in the Search API.

We also want to be able to reindex everything that has been published within a
short period of time (1 or 2 days), so that we can easily recover the index
from backups.

### Moving formats one at a time
We're intending to switch on the new index format-by-format, by querying both old
and new indexes, and using filters to select which index gets used for each
format.

This means we can retire old search indexing code in publishing apps, and search indexes that are no longer needed, without having to populate *everything* all at once.

We can also revert back to the old index with a simple configuration change if something goes wrong.

A problem we've discovered with this approach is that the relevancy of a document within an index depends on the other documents in that index. If an index is only partially populated, the [TF-IDF statistics](https://www.elastic.co/guide/en/elasticsearch/guide/current/scoring-theory.html#tfidf) are less representative, and this affects search results.

## Decision
Firstly, we'll implement a task to bulk-reindex chunks of content from publishing API. Rummager will process this content in the same way as regular publishing updates.

- Reindexing by format lets us initially populate the new index.

- Reindexing by date range lets us bring the `govuk` index up to date when restoring from a backup.

Secondly, when we change the indexing process for a format to use the new index, the format will go through the following phases:

### Phase 1: Untransitioned
At search time, Rummager reads untransitioned formats from the old indexes. Documents belonging to untransitioned formats that are stored in the `govuk` index will be filtered out.

At index time, Rummager will ignore publishing API messages affecting untransitioned formats.

The nightly update job will update the popularity field of untransitioned formats in the `mainstream` index. It will also copy untransitioned format documents from the `mainstream` index into the `govuk` index (it doesn't matter which order these two things happen).

Net effect: untransitioned formats are considered in the TF-IDF statistics of transitioned formats, but are not ready to be returned from the `govuk` index themselves.

### Phase 2: Indexed
At search time, the behaviour is the same as an untransitioned format.

At index time, Rummager will insert documents into the `govuk` index.

The nightly update will update the `popularity` field in the `govuk` index.

As a one off task, we'll delete all existing data for the format from the `govuk` index, and reindex it.

Net effect: the data in the `govuk` index comes from Publishing API data for indexed formats.

### Phase 3: Transitioned
At search time, Rummager reads transitioned formats from the `govuk` index. Documents belonging to transitioned formats that are stored in the `mainstream` index will be filtered out.

At index time, Rummager will insert documents into the `govuk` index.

The nightly update will update the `popularity` field in the `govuk` index.

Net effect: the search API uses Publishing API-derived data for transitioned formats.

## Consequences
Copying `mainstream` data into `govuk` adds a layer of complexity to the nightly popularity updater, that we won't be able to get rid of until we've retired that index.

Since we've decided not implement the ability to generate indexes from scratch now, any content not removed from search when it is unpublished will stay that way forever.

We will continue to address this by [manually removing content in search admin](https://docs.publishing.service.gov.uk/manual/incorrect-content-in-search-or-navigation.html).
