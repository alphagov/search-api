# How Search Works

### Evaluating search results
The `ab_tests` parameter can be used to distinguish between two versions of
the search query.

Using [search-performance-explorer](https://github.com/alphagov/search-performance-explorer),
you can compare the results side by side.

The [health check script](https://github.com/alphagov/search-performance-explorer/blob/master/health-check.md)
can be used to evaluate Search API using a set of judgments about which documents
are 'good' results for some sample queries.
