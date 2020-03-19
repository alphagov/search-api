# How Search Works

Search API provides a `/search` endpoint for users to of the API to search
for documents.

You can also use `/batch_search` to send multiple queries.

## Document retrieval

On receiving a request to `/search` (a search query), Search API will parse
the query, construct an Elasticsearch query, and then retrieve documents
from Elasticsearch.

## Relevancy

If a search query requests that search results be ordered by relevance to the
query, Search API will attempt to order the search results in the most
relevant way possible.

See the [relevancy documentation](doc/relevancy.md) to learn more about how
Search API determines how relevant a document is to a query.

### Reranking

Once Search API has retrieved a selection of relevant documents from
Elasticsearch, the results are re-ranked by a machine learning model.

This process ensures that we show the most relevant documents at the top
of the search results.

See the [learning to rank documentation](doc/learning-to-rank.md) to learn
more about the reranking model.

## Evaluating search quality

To ensure Search API returns good quality results, we use a combination of
offline and online metrics.

See the [search quality metrics documentation](doc/search-quality-metrics.md)
to learn more about our metrics.

The `ab_tests` parameter can be used to distinguish between two versions of
the search query.

Using [search-performance-explorer](https://github.com/alphagov/search-performance-explorer),
you can compare the results side by side.

The [health check script](https://github.com/alphagov/search-performance-explorer/blob/master/health-check.md)
can be used to evaluate Search API using a set of judgments about which documents
are 'good' results for some sample queries.
