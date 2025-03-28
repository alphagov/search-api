# Search API

Search API (née "rummager") indexes content into [Elasticsearch](https://www.elastic.co/products/elasticsearch)
and serves the GOV.UK Search API.

GOV.UK applications use the API to search and filter GOV.UK content.
For example, [alphagov/finder-frontend](https://github.com/alphagov/finder-frontend) uses
the search API to render finder pages (such as [gov.uk/aaib-reports](https://www.gov.uk/aaib-reports)).
[search-api-v2](https://github.com/alphagov/search-api-v2) replaces Search API in several areas: for the latest on this, visit <https://docs.publishing.service.gov.uk/manual/govuk-search.html>.

Search API also provides a public API: https://www.gov.uk/api/search.json?q=taxes.

## Technical documentation

Search API is a Sinatra application that interfaces with Elasticsearch.

You can use the [GOV.UK Docker environment](https://github.com/alphagov/govuk-docker) to run the application and its tests with all the necessary dependencies. Follow [the usage instructions](https://github.com/alphagov/govuk-docker#usage) to get started.

**Use GOV.UK Docker to run any commands that follow.**

### Running the test suite

```
bundle exec rake
```

### Additional Docs

- [Search API documentation](docs/using-the-search-api.md)
- [How documents are indexed](docs/indexing.md)
- [Search relevancy](docs/relevancy.md) - uses [AWS Sagemaker](https://aws.amazon.com/sagemaker/)
- [New indexing process](docs/new-indexing-process.md): how to update a format to use the new indexing process
- [Schemas](docs/schemas.md): how to work with schemas and the document types
- [Publishing document finders](docs/publishing-finders.md): Information about publishing finders using rake tasks

## Licence

[MIT License](LICENCE)
