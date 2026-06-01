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
	maintains separate [indices](https://github.com/alphagov/search-api/blob/main/elasticsearch.yml). Documents are
    served from the 'govuk' index.
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

There is also a separate process that is used for bulk indexing.

	bundle exec rake message_queue:bulk_insert_data_into_govuk

## Schemas

See [schemas](schemas.md) for more detail.

### Changing the schema/Reindexing

After changing the schema, you'll need to recreate the index. This reindexes documents from the existing index.

  SEARCH_INDEX=all bundle exec rake search:migrate_schema

### Representing parts and attachments
Parts are subpages within a single GOV.UK content item, each with its own title, body, and slug. 
They allow one piece of content to be split into multiple sections (e.g., /parent/section-name) without creating separate content items. 
The Search API indexes both parts and HTML attachments using the same parts field, treating them as additional sections of the main document. 
Instead of handling HTML attachments like file downloads, they are stored as extra “parts,” keeping everything in one indexed document while still allowing each attachment’s title and body to be searchable.
