# Adding new fields to a document type

### The schema

`config/schema` contains a bunch of JSON files that together define a schema for documents in Search API. This is described in more detail in the [README](../config/schema/README.md).

First you need to decide which field type to use.
`field_types.json` defines common elasticsearch configuration that we reuse for multiple fields having the same type.

The type you use affects whether the field is [analysed][] by elasticsearch and whether you can use it in [filters][] and [aggregates][].

[analysed]: https://www.elastic.co/guide/en/elasticsearch/guide/current/mapping-analysis.html
[filter]: https://www.elastic.co/guide/en/elasticsearch/reference/5.6/query-filter-context.html
[aggregates]: https://www.elastic.co/guide/en/elasticsearch/reference/5.6/search-aggregations.html

Add your new field to `field_definitions.json`.

If your field should be valid for any kind of document, you can add it to `base_elasticsearch_type.json`. Otherwise, add it to the appropriate JSON file under `elasticsearch_types`.

### Integration testing

The easiest way to test the new fields is to write an integration test for it. These tests run against a development Elasticsearch cluster, and create new search indices each test run.

### Transformation during indexing

Some fields get transformed by Search API before they are stored in Elasticsearch. This is handled by the `DocumentPreparer` class.

### Presenting for search

Some fields get expanded by Search API when they are presented in search results. For example, `specialist_sector` links get expanded by looking up the corresponding documents from the search index and extracting title, content id, and link fields. This is handled by `Search::BaseRegistry`.

### Updating Search API schema indexes on all environments

**Caution:** Do not run this rake task in production during working hours except in an emergency. Content published while the task is running will not be available in search results until the task completes. The impact of this can be reduced if you run the task out of peak publishing hours.

In order for the new field to work as expected, you will need to run a Jenkins job on all environments. The job is "Search reindex with new schema" ([Link to integration version of task][reindex]), and will run the `search:migrate_schema` rake task. It can take over 2 hours to complete.

[reindex]: https://deploy.integration.publishing.service.gov.uk/job/search_api_reindex_with_new_schema/

This job will block other rake tasks from being run for 15 minutes to an hour.

[Read more about re-indexing the elasticsearch indexes here](https://docs.publishing.service.gov.uk/manual/reindex-elasticsearch.html#how-to-reindex-an-elasticsearch-index).

### Troubleshooting

#### The new field doesn't show up

For the new elasticsearch configuration to take effect, you need to manually rebuild the search indexes.

In the past, this was done automatically every night by the [`search_fetch_analytics`](https://github.com/alphagov/search-analytics) jenkins job, but this automation [was reverted](https://github.com/alphagov/search-analytics/commit/a5c3ac58f7198eba74ab7b5bd5555aa07490442a#diff-0484c7ea1cf547a292a2190d0c1c060b). You must run this manually.

If you prefer running a rake task rather than a pre-written Jenkins job, you can run `RUMMAGER_INDEX=all CONFIRM_INDEX_MIGRATION_START=1 search:migrate_schema`.
