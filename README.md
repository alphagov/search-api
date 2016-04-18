# Rummager

Rummager is the internal GOV.UK API for search.

## Live examples

- [alphagov/frontend](https://github.com/alphagov/frontend) uses Rummager to serve the GOV.UK search at [gov.uk/search](https://www.gov.uk/search).
- [alphagov/finder-frontend](https://github.com/alphagov/finder-frontend) uses Rummager to serve document finders like [gov.uk/aaib-reports](https://www.gov.uk/aaib-reports).

This API is publicly accessible:

https://www.gov.uk/api/search.json?q=taxes
![Screenshot of API Response](docs/api-screenshot.png)

## Technical documentation

Rummager is a Sinatra application that interfaces with Elasticsearch.

It provides a [search API](docs/unified-search-api.md) that is used by multiple applications, and is publicly available at [gov.uk/api/search.json](https://www.gov.uk/api/search.json?q=taxes).

There are two ways documents get added to the search index:

1. Post to the [Documents API](docs/documents.md)
2. Via the RabbitMQ consumer worker, which responds to notifications from the [Publishing API](https://github.com/alphagov/publishing-api).

In future the documents API will be deprecated and rummager will consume only from the publishing API.

There is also a separate [API for retrieving documents](docs/content-api.md) from the search index by their links.

Rummager search results are weighted by [popularity](docs/popularity.md). We rebuild the index nightly to incorporate the latest analytics.

## Nomenclature

- **Link**: Either the base path for a content item, or an external link.
- **Document**: An elasticsearch document, something we can search for.
- **Document Type**: An [elasticsearch document type](https://www.elastic.co/guide/en/elasticsearch/guide/current/mapping.html) specifies the fields for a particular type of document. All our document types are defined in [config/schema/document_types](config/schema/document_types)
- **Index**: An [elasticsearch search index](https://www.elastic.co/blog/what-is-an-elasticsearch-index). Rummager maintains several separate indices (`mainstream`, `details`, `government`, and `service-manual`), but searches return documents from all of them.
- **Index Group**: An alias in elasticsearch that points to one index at a time. This allows us to rebuild indexes without downtime.

### Dependencies

- [elasticsearch](https://github.com/elastic/elasticsearch) - "You Know, for Search...".
- [redis](https://github.com/redis/redis) - used by indexing workers.

### Setup

To create indices, or to update them to the latest index settings, run:

    RUMMAGER_INDEX=all bundle exec rake rummager:migrate_index

If you have indices from a Rummager instance before aliased indices, run:

    RUMMAGER_INDEX=all bundle exec rake rummager:migrate_from_unaliased_index

If you don't know which of these you need to run, try running the first one; it
will fail safely with an error if you have an unmigrated index.

### Running the application

If you're running the GDS development VM:

    cd /var/govuk/development && bundle exec bowl rummager

If you're not running the GDS development VM:

    ./startup.sh

Rummager should then be available at [rummager.dev.gov.uk](http://rummager.dev.gov.uk/unified_search.json?q=taxes).

Rummager has an asynchronous mode, using sidekiq to manage index workers in a separate process.
It is disabled in development by default.
To run this in the development VM, you need to run both of these commands:

    # to start the sidekiq process
    ENABLE_QUEUE=1 bundle exec rake jobs:work
    # to start the rummager webapp
    ENABLE_QUEUE=1 bundle exec mr-sparkle --force-polling -- -p 3009

Rummager can subscribe to a queue of updates from publishing-api, backed by rabbitmq.
At present Rummager is only interested in updates to the links hash.
You can start the message queue consumer process in development by running:

    govuk_setenv rummager bundle exec rake message_queue:index_documents_from_publishing_api

### Running the test suite

    bundle exec rake

### Indexing & Reindexing

After changing the schema, you'll need to migrate the index.

    RUMMAGER_INDEX=all bundle exec rake rummager:migrate_index

### API documentation

For the most up to date query syntax and API output:

- [docs/unified-search-api.md](docs/unified-search-api.md) for the unified search
  endpoint (`/unified-search.json`).
- [docs/content-api.md](docs/content-api.md) for the `/content/*` endpoint.
- [docs/documents.md](docs/documents.md) for the `*/documents/` endpoint.

### Additional Docs

- [Health Check](docs/health-check.md): usage instructions for the Health Check functionality.
- [Popularity information](docs/popularity.md): Rummager uses Google Analytics data to improve search results.

## Licence

[MIT License](LICENCE.txt)
