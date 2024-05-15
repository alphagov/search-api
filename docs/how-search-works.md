# How Search Works

Search API provides a `/search` endpoint for users to of the API to search
for documents.

You can also use `/batch_search` to send multiple queries.

## Document retrieval

On receiving a request to `/search` (a search query), Search API will parse
the query, construct an Elasticsearch query, and then retrieve documents
from Elasticsearch.

Search API provides a simplified API so that other applications in the GOV.UK
stack don't need to know how to construct Elasticsearch queries.

## Relevancy

See the [relevancy documentation](relevancy.md) to learn more about how
Search API determines how relevant a document is to a query.

## Evaluating search quality

To ensure Search API returns good quality results, we use a combination of
offline and online metrics.

See the [search quality metrics documentation](search-quality-metrics.md)
to learn more about our metrics.

The `ab_tests` parameter can be used to distinguish between two versions of
the search query.

Using [search-performance-explorer](https://github.com/alphagov/search-performance-explorer),
you can compare the results side by side.

The [health check script](https://github.com/alphagov/search-performance-explorer/blob/master/health-check.md)
can be used to evaluate Search API using a set of judgments about which documents
are 'good' results for some sample queries.
