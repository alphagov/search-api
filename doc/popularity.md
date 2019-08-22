# Popularity information

The gov.uk search uses page popularity information extracted from Google
Analytics as one of the factors in weighting search results.  This is extracted
from Google Analytics by the search-analytics project, but for dev machines,
you should be able to obtain a copy of the page traffic index from preview when
you run the standard replication of search indexes from preview to dev.

If you do need to fetch the analytics data directly yourself, the
[search-analytics project README][] describes how to set up and run
the extraction of page traffic information from Google Analytics.  It
will produce a dump file suitable for loading into an elasticsearch
index using the `page_traffic_load` tool.

Loading popularity data
-----------------------

Once you have the popularity data in a file named, say, `page-traffic.dump`,
load it into elasticsearch using:

    bundle exec bin/page_traffic_load page-traffic < page-traffic.dump

The popularity information won't affect search results until the
`search:update_popularity` rake task is run:

    PROCESS_ALL_DATA=true SEARCH_INDEX=all bundle exec rake search:update_popularity

This creates a lot of Redis jobs, so the [nightly-run.sh][] script
runs the task for one index at a time, with a delay between each.

The popularity information will also be applied when an index
migration is run:

    SEARCH_INDEX=all bundle exec rake search:migrate_schema

How popularity is computed
--------------------------

Popularity is computed by [Indexer::PopularityLookup][], and is
determined by this formula:

```ruby
if ranks[link] == 0
  popularity_score = 0
else
  popularity_score = 1.0 / (ranks[link] + SearchConfig.popularity_rank_offset)
end
```

Where `ranks[link]` gives the ranking of the link in order of number
of page views: the most viewed page is rank 1, the second most vewed
page is rank 2, and so on.

The `popularity_rank_offset` is determined by [the Elasticsearch
configuration file][].

How popularity affects results
------------------------------

Popularity is applied as a multiplier to a document's score.  This is
added by [QueryComponents::Popularity][].

The `POPULARITY_OFFSET` value is added to the popularity score before
multiplying, to ensure that a document with no popularity won't have a
score of zero.  Without this, all such documents would have the same
score, and so would be ranked the same by Elasticsearch, regardless of
how well they match the query.

[search-analytics project README]: https://github.com/alphagov/search-analytics
[nightly-run.sh]: https://github.com/alphagov/search-analytics/blob/master/nightly-run.sh
[Indexer::PopularityLookup]: https://github.com/alphagov/search-api/blob/master/lib/indexer/popularity_lookup.rb
[the Elasticsearch configuration file]: https://github.com/alphagov/search-api/blob/master/elasticsearch.yml
[QueryComponents::Popularity]: https://github.com/alphagov/search-api/blob/master/lib/search/query_components/popularity.rb
