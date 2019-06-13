# Popularity information

The gov.uk search uses page popularity information extracted from Google
Analytics as one of the factors in weighting search results.  This is extracted
from Google Analytics by the search-analytics project, but for dev machines,
you should be able to obtain a copy of the page traffic index from preview when
you run the standard replication of search indexes from preview to dev.

If you do need to fetch the analytics data directly yourself, the
[search-analytics project README](https://github.com/alphagov/search-analytics)
describes how to set up and run the extraction of page traffic information from
Google Analytics.  It will produce a dump file suitable for loading into an
elasticsearch index using the `bulk_load` tool.

Once you have the popularity data in a file named, say, `page-traffic.dump`,
load it into elasticsearch using:

    bundle exec bin/bulk_load page-traffic < page-traffic.dump

The popularity information won't affect search results until an index migration
is run after populating the page-traffic index. As part of the migration, the
popularity for each document will be computed from the page-traffic index and
merged into the documents. To do this, run:

    SEARCH_INDEX=all bundle exec rake search:migrate_schema
