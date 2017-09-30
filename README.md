# Rummager

Rummager is the GOV.UK API for search.

## Live examples

### The public search API
https://www.gov.uk/api/search.json?q=taxes
![Screenshot of API Response](doc/api-screenshot.png)

For the most up to date query syntax and API output see the [Search API documentation](https://docs.publishing.service.gov.uk/apis/search/search-api.html).

You can also find some examples in the blog post: ["Use the search API to get useful information about GOV.UK content"](https://gdsdata.blog.gov.uk/2016/05/26/use-the-search-api-to-get-useful-information-about-gov-uk-content/).

### GOV.UK site search

[alphagov/frontend](https://github.com/alphagov/frontend) uses the search API
to render search results.

### Finders
[alphagov/finder-frontend](https://github.com/alphagov/finder-frontend) uses
the search API to serve document finders like [gov.uk/aaib-reports](https://www.gov.uk/aaib-reports).

## Technical documentation

Rummager is a Sinatra application that interfaces with Elasticsearch.

It provides a [search API](doc/search-api.md) that is used by multiple
applications, and is publicly available at
[gov.uk/api/search.json](https://www.gov.uk/api/search.json?q=taxes).

There are two ways documents get added to the search index:

1. Post to the [Documents API](doc/documents.md)
2. Via the RabbitMQ consumer worker, which responds to notifications from the
	 [Publishing API](https://github.com/alphagov/publishing-api).

In future the documents API will be deprecated and rummager will consume only
from the publishing API.

There is also a separate [API for retrieving documents](doc/content-api.md)
from the search index by their links.

Rummager search results are weighted by [popularity](doc/popularity.md). We
rebuild the index nightly to incorporate the latest analytics.

## Nomenclature

- **Link**: Either the base path for a content item, or an external link.
- **Document**: An elasticsearch document, something we can search for.
- **Document Type**: An [elasticsearch document
	type](https://www.elastic.co/guide/en/elasticsearch/guide/current/mapping.html)
	specifies the fields for a particular type of document. All our document
	types are defined in
	[config/schema/elasticsearch_types](config/schema/elasticsearch_types)
- **Index**: An [elasticsearch search
	index](https://www.elastic.co/blog/what-is-an-elasticsearch-index). Rummager
	maintains several separate indices (`mainstream`, `detailed` and
	`government`), but searches return documents from all of them.
- **Index Group**: An alias in elasticsearch that points to one index at a
	time. This allows us to rebuild indexes without downtime.

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

Rummager should then be available at
[rummager.dev.gov.uk](http://rummager.dev.gov.uk/search.json?q=taxes).

Rummager uses Sidekiq to manage index workers in a separate process. To run
this in the development VM, you need to run both of these commands:

    # to start the sidekiq process
    bundle exec rake jobs:work

    # to start the rummager webapp
    bundle exec mr-sparkle --force-polling -- -p 3009

Rummager can subscribe to a queue of updates from publishing-api, backed by
rabbitmq.  At present Rummager is only interested in updates to the links hash.
You can start the message queue consumer process in development by running:

    govuk_setenv rummager bundle exec rake message_queue:listen_to_publishing_queue

### Running the test suite

    bundle exec rake

### Indexing & Reindexing

After changing the schema, you'll need to migrate the index.

    RUMMAGER_INDEX=all bundle exec rake rummager:migrate_index

#### Internal only APIs

There are some other APIs that are only exposed internally:

- [doc/content-api.md](doc/content-api.md) for the `/content/*` endpoint.
- [doc/documents.md](doc/documents.md) for the `*/documents/` endpoint.


### Additional Docs

- [Schemas](doc/schemas.md): how to work with schemas and the document types
- [Health Check](doc/health-check.md): usage instructions for the Health Check
	functionality.
- [Popularity information](doc/popularity.md): Rummager uses Google Analytics
	data to improve search results.

## Licence

[MIT License](LICENCE.txt)
