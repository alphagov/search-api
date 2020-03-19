# Search API

Search API (née "rummager") indexes content into [Elasticsearch](https://www.elastic.co/products/elasticsearch)
and serves the GOV.UK Search API.

GOV.UK applications use the API to search and filter GOV.UK content.
For example, [alphagov/finder-frontend](https://github.com/alphagov/finder-frontend) uses
the search API to render [site search](https://www.gov.uk/search) and finder pages
(such as [gov.uk/aaib-reports](https://www.gov.uk/aaib-reports)).

Search API also provides a public API: https://www.gov.uk/api/search.json?q=taxes.

![Screenshot of API Response](doc/api-screenshot.png)

## API documentation

If you would like to use the Search API, please see the
[Search API documentation](https://docs.publishing.service.gov.uk/apis/search/search-api.html).

You can also find some examples in the blog post:
["Use the search API to get useful information about GOV.UK content"](https://gdsdata.blog.gov.uk/2016/05/26/use-the-search-api-to-get-useful-information-about-gov-uk-content/).

## Getting started

The instructions will help you to get Search API running
locally on your machine.

### Prequisites

Install [govuk-docker](https://github.com/alphagov/govuk-docker)!

govuk-docker, a wrapper around docker-compose, is the supported way
to run Search API and its dependencies locally.

Once you have installed govuk-docker, run

	cd ~/govuk/govuk-docker && make search-api

### Running the application

Once you have completed the prerequisites you'll be able to run
Search API locally by running

	cd ~/govuk/search-api && govuk-docker up search-api-app

This starts the Search API application and its dependencies.

The Search API will be running locally at [search-api.dev.gov.uk](search-api.dev.gov.uk/search).

If you run `docker ps` this will tell you that there are containers running
for Search API, Nginx, Redis, Publishing API, and Elasticsearch.

> Note: If you're not using docker, you can run `./startup.sh` to start the
application. However, this is not officially supported, and you will need to
run dependencies such as Elasticsearch and Redis yourself.

#### Replicating data locally

If you've started running Search API for the first time you probably
aren't seeing any search results for your queries. That's likely
because your local search indexes will be empty.

Once you have got everything running locally, another step most
people take is to get a copy of the search indexes running locally.
This will let you search for real documents on your local machine.

See the govuk-docker [documentation on replicating data](https://github.com/alphagov/govuk-docker#how-to-replicate-data-locally),
or run

	gds aws govuk-integration-poweruser ./bin/replicate-elasticsearch.sh

Refer to the govuk-docker documentation for more details about
the replication scripts.

### Running the test suite

Complete the prerequisites, then run

	govuk-docker run search-api-lite bundle exec rake

> Note: You can also run the tests without using docker, by running
`bundle exec rake`. This is not officially supported, but can be a quick way
to run unit tests.

## Technical documentation

Search API is a Sinatra application that interfaces with Elasticsearch.

Search API puts documents into Elasticsearch indexes (index time), and serves
documents in search results (query time).

It does some clever stuff at both parts, but that's the meat of it.

Read the [documentation](/doc) to find out [how documents are indexed](doc/indexing.md)
or [how documents are retrieved](doc/how-search-works.md).

### Dependencies

Search API depends on other services in order to index documents and provide
relevant search results:

- [Elasticsearch](https://github.com/elastic/elasticsearch) - "You Know, for Search...".
- [Redis](https://redis.io/) - used by indexing workers.
- [AWS Sagemaker](https://aws.amazon.com/sagemaker/) (optional) - used for [search relevancy](docs/relevancy.md)

If you use govuk-docker locally, the required dependencies will be started
automatically when you start Search API. You don't need to set these up yourself.

See the [learning to rank documentation](doc/learning-to-rank.md) for
guidance on how to run the ranking model locally.

### Additional Docs

- [New indexing process](doc/new-indexing-process.md): how to update a format to use the new indexing process
- [Schemas](doc/schemas.md): how to work with schemas and the document types
- [Popularity information](doc/popularity.md): Search API uses Google Analytics
	data to improve search results.
- [Publishing document finders](doc/publishing-finders.md): Information about publishing finders using rake tasks

## Licence

[MIT License](LICENCE.txt)
