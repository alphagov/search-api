# Search API

Search API (née "rummager") indexes content into [Elasticsearch](https://www.elastic.co/products/elasticsearch)
and serves the GOV.UK Search API.

GOV.UK applications use the API to search and filter GOV.UK content.
For example, [alphagov/finder-frontend](https://github.com/alphagov/finder-frontend) uses
the search API to render [site search](https://www.gov.uk/search) and finder pages
(such as [gov.uk/aaib-reports](https://www.gov.uk/aaib-reports)).

Search API also provides a public API: https://www.gov.uk/api/search.json?q=taxes.

![Screenshot of API Response](docs/api-screenshot.png)

## API documentation

If you would like to use the Search API, please see the
[Search API documentation](https://docs.publishing.service.gov.uk/apis/search/search-api.html).

You can also find some examples in the blog post:
["Use the search API to get useful information about GOV.UK content"](https://gdsdata.blog.gov.uk/2016/05/26/use-the-search-api-to-get-useful-information-about-gov-uk-content/).

## Technical documentation

Search API is a Sinatra application that interfaces with Elasticsearch.

You can use the [GOV.UK Docker environment](https://github.com/alphagov/govuk-docker) to run the application and its tests with all the necessary dependencies. Follow [the usage instructions](https://github.com/alphagov/govuk-docker#usage) to get started.

**Use GOV.UK Docker to run any commands that follow.**

### Running the test suite

```
bundle exec rake
```

### Additional Docs

- [How documents are indexed](docs/indexing.md)
- [How documents are retrieved](docs/how-search-works.md)
- [Search relevancy](docs/relevancy.md) - uses [AWS Sagemaker](https://aws.amazon.com/sagemaker/)
- [New indexing process](docs/new-indexing-process.md): how to update a format to use the new indexing process
- [Schemas](docs/schemas.md): how to work with schemas and the document types
- [Popularity information](docs/popularity.md): Search API uses Google Analytics data to improve search results.
- [Publishing document finders](docs/publishing-finders.md): Information about publishing finders using rake tasks
- [Learning to rank](docs/learning-to-rank.md): Guidance on how to run the ranking model locally

## Licence

[MIT License](LICENCE.txt)
