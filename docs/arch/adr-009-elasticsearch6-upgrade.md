# Decision record: Upgrade to Elasticsearch 6

**Date:** 2019-10-03

1. [High-level migration plan](#high-level-migration-plan)
1. [New cluster architecture](#new-cluster-architecture)
1. [Elasticsearch 6 compatibility](#elasticsearch-6-compatibility)
1. [Connecting to multiple Elasticsearch clusters](#connecting-to-multiple-elasticsearch-clusters)
1. [Synchronising the state](#synchronising-the-state)
1. [Data sync for production -> staging -> integration](#data-sync-for-production---staging---integration)
1. [A/B testing Elasticsearch 6](#ab-testing-elasticsearch-6)
1. [Decomissioning Elasticsearch 5](#decomissioning-elasticsearch-5)

This work was done over 2019/20 Q1 and Q2.  Most of the changes were
made in this repository.  There were also significant changes in
[govuk-aws][], [govuk-aws-data][], and [govuk-puppet][].

[govuk-aws]: https://github.com/alphagov/govuk-aws
[govuk-aws-data]: https://github.com/alphagov/govuk-aws-data
[govuk-puppet]: https://github.com/alphagov/govuk-puppet


## High-level migration plan

Based on our experiences [migrating to Elasticsearch 5][] we decided
that this time we wanted to isolate the complexity of having two
Elasticsearch clusters to search-api:

1. Make search-api work with both Elasticsearch 5 and Elasticsearch 6.
2. Give search-api support for multiple Elasticsearch clusters:
   - Index changes into all clusters.
   - Add a URL parameter to select the cluster to use for a query.
3. Perform a one-time import of data from Elasticsearch 5 to
   Elasticsearch 6, and synchronise any updates missed while this
   import was running.
4. Confirm that the Elasticsearch 5 and Elasticsearch 6 clusters are
   consistent.
5. Set up an A/B test for finder-frontend (etc) to select which
   Elasticsearch cluster to use.
6. Gradually phase from 100% Elasticsearch 5 to 100% Elasticsearch 6.
7. Retire Elasticsearch 5.

The approach we took last time of having both rummager and search-api
running in parallel, necessitated by one being in Carrenza and one in
AWS, led to a lot of changes to govuk-puppet, and didn't really give
us anything reusable.  By adding multi-cluster support to search-api
directly, we do get something reusable.

[migrating to Elasticsearch 5]: https://github.com/alphagov/search-api/blob/master/docs/arch/adr-008-elasticsearch5-upgrade.md


## New cluster architecture

Based on our experience of running Elasticsearch 5 for a quarter, we
at first opted for:

- Three dedicated master nodes, of type `c4.large.elasticsearch`.
- Six data nodes, of type `r4.large.elasticsearch`.

We found the data nodes were not powerful enough, and switched to
`r4.xlarge.elasticsearch`.  After talking to an AWS Solutions
Architect, we changed again to `r5.xlarge.elasticsearch`.  Due to
wider GOV.UK scaling concerns caused by political activity, we
increased the data nodes to `r5.2xlarge.elasticsearch`.

We also shrunk the cluster in staging (to below production size), as
it does not need to cope with the indexing load.  The final cluster
sizes are:

| Environment | Master                       | Data                          |
| ----------- | ---------------------------- | ----------------------------- |
| Production  | 3x `c4.large.elasticsearch`  | 6x `r5.2xlarge.elasticsearch` |
| Staging     | 3x `c4.large.elasticsearch`  | 3x `r5.2xlarge.elasticsearch` |
| Integration | 3x `t2.medium.elasticsearch` | 3x `r5.large.elasticsearch`   |


The cluster is configured in the [app-elasticsearch6][] Terraform
project.

[app-elasticsearch6]: https://github.com/alphagov/govuk-aws/tree/master/terraform/projects/app-elasticsearch6


## Elasticsearch 6 compatibility

We used deprecation messages from Elasticsearch 5 and error messages
from Elasticsearch 6 to figure out what needed to change.  There were
some changes needed to the indices and some to the queries.

Index changes were:

- Switching from `string` fields to `text` and `keyword` fields ([PR #1553](https://github.com/alphagov/search-api/pull/1553)).
- Removing the use of the `_all` field and `include_in_all` ([PR #1557](https://github.com/alphagov/search-api/pull/1557)).

Query changes were:

- Using `like` instead of `docs` in the `more_like_this` query ([PR #1561](https://github.com/alphagov/search-api/pull/1561)).
- Replacing `match: { type: phrase }` with `match_phrase` queries ([PR #1564](https://github.com/alphagov/search-api/pull/1564)).
- Replacing `indices` query with a `should` query ([PR #1568](https://github.com/alphagov/search-api/pull/1568)).

The `indices`/`should` change introduced an inefficiency where query
generation now needs to ask Elasticsearch for the real name of an
alias.  We added a new `build_query` metric to keep track of this.
[Elasticsearch issue #23306][], opened in February 2017, is about a
solution to this problem.

We also changed the text similarity metric from [classic similarity][]
to the new [BM25 similarity][].

[Elasticsearch issue #23306]: https://github.com/elastic/elasticsearch/issues/23306
[classic similarity]: https://www.elastic.co/guide/en/elasticsearch/reference/6.0/index-modules-similarity.html#classic-similarity
[BM25 similarity]: https://www.elastic.co/guide/en/elasticsearch/reference/6.0/index-modules-similarity.html#bm25


## Connecting to multiple Elasticsearch clusters

The `elasticsearch.yml` file contains a list of clusters.  These
clusters can specify their own schema configuration file, which means
we can try out different index-level settings in a new cluster (for
example, changing the text similarity metric only for Elasticsearch
6).

In the code, the multi-cluster support is implemented in the
`SearchConfig` and `Index::Client` classes.  Cluster selection is
implemented in the `SearchParameterParser` class.

This involved some significant refactoring ([PR #1569][] and [PR
#1604][]).

The main architectural decisions made here were:

- To index writes to all clusters, ensuring cluster consistency.
- To perform queries against the default cluster unless a URL
  parameter is given, so we can A/B test clusters.
- To have one `SearchConfig` singleton per cluster.

This change did result in details of clusters leaking throughout
search-api, which is unfortunate, but that can be addressed in future
refactoring work (for example, passing around `SearchConfig` instances
rather than asking for cluster singletons).

[PR #1569]: https://github.com/alphagov/search-api/pull/1569
[PR #1604]: https://github.com/alphagov/search-api/pull/1604


## Synchronising the state

We planned to either take a snapshot from Elasticsearch 5 and restore
it to Elasticsearch 6, or to use the same approach as the last upgrade
(a script to copy the data across), but these turned out to be
unnecessary.

We had search-api running with both clusters for a couple of weeks
before we started to think about synchronising the data, and by that
time everything had been republished (either directly or as a result
of dependency resolution) and so the `govuk`, `government`, and
`detailed` indices were consistent with Elasticsearch 5.

The `page-traffic` index was also handled in the multi-cluster work,
with traffic data being saved to all clusters.

The only index which needed some manual work was `metasearch`, which
holds best bets.  Attempting to republish these from [search-admin][]
kept failing due to transient network issues, and getting all of the
best bets seemed impossible.  So for the `metasearch` index we used
this script:

```python
from elasticsearch5 import Elasticsearch as Elasticsearch5, TransportError as TransportError5
from elasticsearch6 import Elasticsearch as Elasticsearch6, TransportError as TransportError6
from elasticsearch6.helpers import bulk
from datetime import datetime
import os

INDEX = 'metasearch'
GENERIC_DOC_TYPE = 'generic-document'

ES5_HOST_PORT = os.getenv('ES5_ORIGIN_HOST', 'http://elasticsearch5:80')
ES6_TARGET_PORT = os.getenv('ES6_TARGET_HOST', 'http://elasticsearch6:80')

es_client5 = Elasticsearch5([ES5_HOST_PORT])
es_client6 = Elasticsearch6([ES6_TARGET_PORT])


def _prepare_docs_for_bulk_insert(docs):
    for doc in docs:
        yield {
            "_id": doc['_id'],
            "_source": doc['_source'],
        }

def bulk_index_documents_to_es6(documents):
    try:
        bulk(
            es_client6,
            _prepare_docs_for_bulk_insert(documents),
            index=INDEX,
            doc_type=GENERIC_DOC_TYPE,
            chunk_size=100
        )
    except TransportError6 as e:
        print("Failed to index documents: %s", str(e))


def fetch_documents(from_=0, page_size=100, scroll_id=None):
    try:
        if scroll_id is None:
            results = es_client5.search(INDEX, GENERIC_DOC_TYPE, from_=from_, size=page_size, scroll='2m')
            scroll_id = results['_scroll_id']
        else:
            results = es_client5.scroll(scroll_id=scroll_id, scroll='2m')
        docs = results['hits']['hits']
        return (scroll_id, docs)
    except TransportError5 as e:
        print("Failed to fetch documents: %s", str(e))
        return str(e), e.status_code


if __name__ == '__main__':
    start = datetime.now()

    dcount = es_client5.count(index=INDEX, doc_type=GENERIC_DOC_TYPE)['count']

    print('Preparing to index {} document(s) from ES5'.format(dcount))

    offset = 0
    page_size = 250
    scroll_id = None
    while offset <= dcount:
        scroll_id, docs = fetch_documents(from_=offset, page_size=page_size, scroll_id=scroll_id)

        print('Indexing documents {} to {} into ES6'.format(offset, offset+page_size))
        bulk_index_documents_to_es6(docs)

        offset += page_size

    print('Finished in {} seconds'.format(datetime.now() - start))
```

[search-admin]: https://github.com/alphagov/search-admin


## Data sync for production -> staging -> integration

This was done in the same way [as for Elasticsearch 5][].

The data sync script needed to be modified to allow for a different
host to be used (`http://elasticsearch6` vs `http://elasticsearch5`)
but otherwise this was just a matter of writing some more
configuration.

[as for Elasticsearch 5]: https://github.com/alphagov/search-api/blob/master/docs/arch/adr-008-elasticsearch5-upgrade.md


## A/B testing Elasticsearch 6

The A/B test was set up like so:

1. Configuration in govuk-cdn-config.
2. Logic in finder-frontend to pass one of two URL parameters to
   search-api, based on the CDN-level A/B test.
3. Logic in search-api to choose a cluster based on the parameter from
   finder-frontend.

The general A/B test process [is covered in the dev docs][].

For the A/B test we monitored click-through rate, proportion of search
refinements, and proportion of search exits.  The test revealed a
significant degradation in our metrics compared with Elasticsearch 5,
and we were unable to proceed with the switch without doing work to
improve the search results.

The two main changes in Elasticsearch 6 which impacted search result
quality were:

- Switching from classic similarity to [BM25 similarity][].  This
  issue arose with Elasticsearch 5, but we decided to go ahead with
  the new similarity when moving to Elasticsearch 6.

- The removal of query coordination factors, affecting the scoring of
  multi-clause `should` and `must` queries.  This meant that even if
  we switched back to classic similarity, we wouldn't get the same
  results we had with Elasticsearch 5.

With query coordination factors, multi-clause `should` and `must`
queries are scored as:

```
sum(clause scores) * num(matching clauses) / num(clauses)
```

So if a query has 7 clauses and 2 of them match, the overall score is
multipled by 2/7.  The effect of this is to make documents which match
multiple clauses tend to rank higher than documents which match fewer
clauses, even if those fewer clauses are matched really well.  The
assumption is that the number of matching clauses is an important
predictor of relevance.

Without query coordination factors, the query is scored as:

```
sum(clause scores)
```

Figuring out how to improve the search query was not a
straightforward, or particularly systematic, process.

Our Elasticsearch 5 query is:

```ruby
{
  bool: {
    should: [
      match_phrase("title", query),
      match_phrase("acronym", query),
      match_phrase("description", query),
      match_phrase("indexable_content", query),
      match_all_terms(%w(title acronym description indexable_content), query),
      match_any_terms(%w(title acronym description indexable_content), query),
      minimum_should_match("all_searchable_text", query)
    ],
  }
}
```

And the Elasticsearch 6 query we settled on is:

```ruby
should_coord_query([
  match_all_terms(%w(title), query, MATCH_ALL_TITLE_BOOST),
  match_all_terms(%w(acronym), query, MATCH_ALL_ACRONYM_BOOST),
  match_all_terms(%w(description), query, MATCH_ALL_DESCRIPTION_BOOST),
  match_all_terms(%w(indexable_content), query, MATCH_ALL_INDEXABLE_CONTENT_BOOST),
  match_all_terms(%w(title acronym description indexable_content), query, MATCH_ALL_MULTI_BOOST),
  match_any_terms(%w(title acronym description indexable_content), query, MATCH_ANY_MULTI_BOOST),
  minimum_should_match("all_searchable_text", query, MATCH_MINIMUM_BOOST)
])
```

Here `should_coord_query` is [a reimplementation of the query
coordination factor-based scoring][], using a [function_score][]
query.  We also changed the `match_phrase` clauses in the
Elasticsearch 5 query to `match_all_terms` clauses, and adjusted the
field boosting factors.

We then ran the A/B test again, and found that the Elasticsearch 6
with the new query had a clickthrough rate within 3 percentage points
of Elasticsearch 5 with the old query, and decided that this was good
enough to go ahead with the switch.

[is covered in the dev docs]: https://docs.publishing.service.gov.uk/manual/run-ab-test.html
[a reimplementation of the query coordination factor-based scoring]: https://github.com/alphagov/search-api/blob/df38c7ecc2af5e2c21d12096d10aca79ce900310/lib/search/query_helpers.rb#L62-L84
[function_score]: https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-function-score-query.html


## Decomissioning Elasticsearch 5

The steps we followed to switch to Elasticsearch 6 permanently and to
decomission Elasticsearch 5 were:

1. Switch search-api to the B variant of the A/B test and disable the A cluster so no more indexing is done ([PR #1713](https://github.com/alphagov/search-api/pull/1713)).
2. Disable the A/B test in govuk-cdn-config ([PR #203](https://github.com/alphagov/govuk-cdn-config/pull/203)) and finder-frontend ([PR #1611](https://github.com/alphagov/finder-frontend/pull/1611)).
3. Remove Elasticsearch 5 configuration from govuk-puppet ([PR #9643](https://github.com/alphagov/govuk-puppet/pull/9643)).
4. Remove Elasticsearch 5 from govuk-aws ([PR #1123](https://github.com/alphagov/govuk-aws/pull/1123)).

We didn't want to be permanently using the "B" configuration, which
required some care to change:

1. Set the `ELASTICSEARCH_URI` environment variable to the same value as the `ELASTICSEARCH_B_URI` environment variable in govuk-puppet ([PR #9648](https://github.com/alphagov/govuk-puppet/pull/9648)).
2. Swap out the "B" cluster configuration for the "A" cluster configuration ([PR #1718](https://github.com/alphagov/search-api/pull/1718)).
3. Unset the `ELASTICSEARCH_B_URI` environment variable in govuk-puppet ([PR #9649](https://github.com/alphagov/govuk-puppet/pull/9649)).

This approach avoided the need to coordinate simultaneous deploys of
search-api and govuk-puppet.
