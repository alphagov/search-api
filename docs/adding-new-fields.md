---
title: Adding new fields to rummager
layout: default
---

### The schema

`config/schema` contains a bunch of JSON files that together define a schema for documents in rummager. This is described in more detail in the [README](../config/schema/README.md).

First you need to decide which field type to use.
`field_types.json` defines common elasticsearch configuration that we reuse for multiple fields having the same type.

The type you use affects whether the field is [analysed](https://www.elastic.co/guide/en/elasticsearch/guide/current/mapping-analysis.html) by elasticsearch and whether you can use it in [filters](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-filter-context.html) and [facets](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-facets.html).

Add your new field to `field_definitions.json`.

If your field should be valid for any kind of document, you can add it to `base_elasticsearch_type.json`. Otherwise, add it to the appropriate JSON file under `elasticsearch_types`.

### Integration testing

The easiest way to test the new fields is to write an integration test for it. These tests run against a development Elasticsearch cluster, and create new search indices each test run.

### Transformation during indexing

Some fields get transformed by rummager before they are stored in Elasticsearch. This is handled by the `DocumentPreparer` class.

### Presenting for search

Some fields get expanded by rummager when they are presented in search results. For example, `specialist_sector` links get expanded by looking up the corresponding documents from the search index and extracting title, content id, and link fields. This is handled by `Search::BaseRegistry`.

### Troubleshooting

#### The new field doesn't show up immediately

For the new elasticsearch configuration to take effect, you need to rebuild the search indexes.

On production, this is done automatically every night by the [`search_fetch_analytics`](https://github.com/alphagov/search-analytics) jenkins job.

For other environments, you can run `RUMMAGER_INDEX=all SKIP_LINKS_INDEXING_TO_PREVENT_TIMEOUTS=1 rummager:migrate_index`.
