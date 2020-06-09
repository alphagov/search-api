# Indexing

Elasticsearch, the search engine operated by Search API, stores documents
in *indexes*.

This document describes how documents are indexed (added to Elasticsearch indexes).

<!-- TODO: this is a stub; we should describe in more detail how
documents are added to the search indexes -->

## Nomenclature

- **Link**: Either the base path for a content item, or an external link.
- **Document**: An elasticsearch document, something we can search for.
- **Document Type**: An [elasticsearch document
	type](https://www.elastic.co/guide/en/elasticsearch/guide/current/mapping.html)
	specifies the fields for a particular type of document. All our document
	types are defined in
	[config/schema/elasticsearch_types](config/schema/elasticsearch_types)
- **Index**: An [elasticsearch search
	index](https://www.elastic.co/blog/what-is-an-elasticsearch-index). Search API
	maintains several separate indices (`detailed`, `government` and `govuk`),
	but searches return documents from all of them.
- **Index Group**: An alias in elasticsearch that points to one index at a
	time. This allows us to rebuild indexes without downtime.


## How documents get added to the search indexes

There are two ways documents get added to a search index:

1. HTTP requests to Search API's [Documents API](documents.md) (deprecated)
2. Search API subscribes to RabbitMQ messages from the
	 [Publishing API](https://github.com/alphagov/publishing-api).

Search API search results are weighted by [popularity](popularity.md). We
rebuild the index nightly to incorporate the latest analytics.

#### Publishing API integration

Search API subscribes to a RabbitMQ queue of updates from publishing-api. This
still requires Sidekiq to be running.

	bundle exec rake message_queue:insert_data_into_govuk

There is also a separate process that listens to only 'links' updates from the publishing API. This is used for updating old indexes that are populated through the '/documents' API (`government`, `detailed`) and can be removed once those indexes no longer exist.

	bundle exec rake message_queue:listen_to_publishing_queue

### Internal only APIs

There are some other APIs that are only exposed internally:

- [content-api.md](content-api.md) for the `/content/*` endpoint.
- [documents.md](documents.md) for the `*/documents/` endpoint.

These are used by [search admin](https://github.com/alphagov/search-admin/).

## Schemas

See [schemas](schemas.md) for more detail.

### Changing the schema/Reindexing

After changing the schema, you'll need to recreate the index. This reindexes documents from the existing index.

  SEARCH_INDEX=all bundle exec rake search:migrate_schema
