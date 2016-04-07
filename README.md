# Rummager

Rummager is the internal GOV.UK API for search.

## Live examples

- [alphagov/frontend](https://github.com/alphagov/frontend) uses Rummager to serve the GOV.UK search at [gov.uk/search](https://www.gov.uk/search).
- [alphagov/finder-frontend](https://github.com/alphagov/finder-frontend) uses Rummager to serve document finders like [gov.uk/aaib-reports](https://www.gov.uk/aaib-reports).

This API is publicly accessible:

https://www.gov.uk/api/search.json?q=taxes
![Screenshot of API Response](docs/api-screenshot.png)

## Technical documentation

This is a Sinatra application that provides an API for search to multiple applications. It isn't supposed to be used by regular users, but it is publicly available on [gov.uk/api/search.json](https://www.gov.uk/api/search.json?q=taxes).

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
