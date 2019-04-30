# Decision record: Upgrade to Elasticsearch 5

**Date:** 2019-04-30

1. [High-level migration plan](#high-level-migration-plan)
1. [Running search-api and rummager in parallel](#running-search-api-and-rummager-in-parallel)
1. [Elasticsearch 5 compatibility](#elasticsearch-5-compatibility)
1. [Looking to the future: Elasticsearch 6 compatibility](#looking-to-the-future-elasticsearch-6-compatibility)
1. [New cluster architecture](#new-cluster-architecture)
1. [Synchronising the state](#synchronising-the-state)
1. [Switching over the applications](#switching-over-the-applications)
1. [Staging teething problems](#staging-teething-problems)
1. [Production teething problems](#production-teething-problems)
1. [Data sync for production -> staging -> integration](#data-sync-for-production---staging---integration)
1. [Dockerising the development VM](#dockerising-the-development-vm)

This work was done over 2018/19 Q4.  All of the changes to rummager /
search-api are contained in [PR #1439][].  There were also significant
changes in [govuk-aws][], [govuk-aws-data][], and [govuk-puppet][],
with various other repositories having small changes as well.

Terminology:

- **rummager** is the Elasticsearch 2 search service, and is deployed
  to Carrenza (in staging and production).

- **search-api** is the Elasticsearch 5 search service, and is
  deployed to AWS.


## High-level migration plan

We decided on two high-level objectives before any further planning:

- This should be a close-to-zero-downtime switch.

- We don't want to set up new infrastructure in Carrenza.

A consequence of those is that we needed to have, at least
temporarily, two Elasticsearch clusters (Elasticsearch 2 in Carrenza
and Elasticsearch 5 in AWS).  The rest of the plan came out of that
decision:

1. Create a fork of rummager called "search-api", which will run on a
   different port and be deployed to AWS.
1. Make search-api work with Elasticsearch 5.
1. Arrange for updates sent to rummager to also be sent to search-api.
1. Set up a new Elasticsearch 5 cluster.
1. Perform a one-time import of data from Elasticsearch 2 to
   Elasticsearch 5, and synchronise any updates missed while this
   import was running.
1. Confirm that the Elasticsearch 2 and Elasticsearch 5 clusters are
   consistent.
1. Use Plek to make applications which only read from search use
   search-api.
1. Use Plek to make applications which write to search use search-api.
1. Retire rummager, Elasticsearch 2, and anything related.

[licence-finder][] also uses Elasticsearch.  It only stores a small
amount of data, and can reindex in under a minute, so we decided not
to go through the complication of running a second licence-finder.  As
soon as the new Elasticsearch cluster existed in production, we
switched over licence-finder.


## Running search-api and rummager in parallel

This was largely a matter of following the "[Set up a new Rails
application][]" documentation, with the main difference being that we
were basing the configuration for the search-api on the existing
Puppet (etc) code for rummager.

The changes needed to the rummager configuration were:

- Changing the port from 3009 to 3233 (the first available free port).
- Changing the redis namespace from "rummager" to "search-api".
- Changing the rabbitmq namespace from "rummager" to "search-api".

Additionally, the "search-api" hostname needed adding to the Terraform
configuration.


## Elasticsearch 5 compatibility

The Elasticsearch 5 release notes includes [a large section on
breaking changes][].  Neither of the developers on the team knew
Elasticsearch at the start of the quarter, so this section served to
guide us into the necessary documentation.

The main changes which we had to address were structural changes to
the query language, which were generally straightforward to resolve.

There were two more complex issues which will need to be revisited
when moving to Elasticsearch 6:

- The default text similarity metric changed from the "classic"
  algorithm to BM25.  We encountered problems with result ordering,
  possibly due to this, and switched back to the classic algorithm.

- The Elasticsearch 2 `string` type has been split into two new types,
  `keywords` and `text`, with different behaviours.  Elasticsearch 5
  internally transforms a single `string` field into two fields of the
  new types, transparently handling indexing and querying.  We did not
  update our schemas to use `text`/`keywords`.


## Looking to the future: Elasticsearch 6 compatibility

Elasticsearch 2 and 5 allow having multiple document types in the same
index.  Elasticsearch 6 does not allow this.

There are two ways to solve the problem:

- Combine all the types into one large type, and add a "type" field
  which the application uses.
- Add a separate index for each type.

We decided to combine all the types in each index into one big type,
and added a `document_type` field to distinguish them.  As this is
what Elasticsearch 2 did anyway (all documents in the same Lucene
index must be of the same type), we do not think this imposes any
additional overhead.

search-api still validates documents against schemas, it just uses a
different field to hold the type.  The external API has not been
changed.


## New cluster architecture

We decided to use an AWS managed Elasticsearch cluster.  Self-managing
Elasticsearch is undesirable because:

- Nobody knows how to manage Elasticsearch.
- Our version of Puppet is so old we can't use a version of
  [puppet-elasticsearch][] which supports Elasticsearch 6.
- It's much harder to scale.

We designed a new cluster architecture based on the resources
allocated to the current Elasticsearch 2 cluster, but it proved to not
be sufficient.  At the time of writing, the cluster has:

- Three dedicated master nodes, of type `c4.large.elasticsearch`.
- Six data nodes, of type `r4.large.elasticsearch`.

The cluster is configured by the [app-elasticsearch5][] Terraform
project.


## Synchronising the state

There are two steps to this:

- Ensuring search updates sent to rummager are also sent to search-api.
- Import the current Elasticsearch 2 data.

First we ensured that updates were sent to search-api, as there
wouldn't be any point in importing data which would immediately become
out of date.

There are three ways in which data gets into rummager:

- From the publishing-api via rabbitmq.
- From search-admin over HTTP.
- From whitehall over HTTP.

The publishing-api updates were already handled by us setting up
search-api in a similar way to rummager.  We handled the HTTP updates
by using traffic replay: all traffic sent to rummager was also sent to
search-api.  This was not 100% reliable, and occasionally dropped
documents, but in such cases re-sending the document from whitehall to
rummager made it also appear in search-api.

For the data import, we have a script to fetch the documents from
Elasticsearch 2, transform them into the new single-type format, and
insert them into Elasticsearch 5: [elasticsearch-migration-helpers][].

We created fresh search indices, ran the import script, and replayed
any updates that had been missed due to that running.


## Switching over the applications

We handled the application switch-over with Plek.  We gave each
search-using application a new parameter in Puppet, to specify a URL
which should be set for the `PLEK_SERVICE_RUMMAGER_URI` and
`PLEK_SERVICE_SEARCH_URI` environment variables.  We could configure
this through the hieradata, allowing applications to be switched over
independently of other applications or how they were configured in
other environments.

We switched over each environment independently.  The only constraint
on the order of changes is that applications which update search
should be done after applications which query search, to avoid an
inconsistent state where some things are querying rummager but other
things are only updating search-api.

For the production switch-over we divided the applications by
riskiness:

1. collections and licence-finder
1. finder-frontend
1. content-tagger and hmrc-manuals-api
1. search-admin and whitehall (frontend and backend)

We then set the rummager [X-Ray][] recording to 100%, to verify that
only monitoring was still talking to it.


## Staging teething problems

We discovered some significant problems during manual testing in
staging which delayed the production roll-out by a few weeks.  These
were:

- **Very strange result ordering.** We resolved this by switching back
  to the classic text similarity and back to using `string` fields.
  These are mentioned in more detail further up.

- **Every query returned every best bet.** This was due to a mistake
  made when combining all the types.

- **Indices would automatically unlock.** This was due to an AWS
  process which runs every four minutes: locking the indices if the
  cluster is unhealthy and unlocking them if it is healthy.  We
  changed to using `read_only_allow_delete`, which introduced some
  benign (but potentially confusing) race conditions in importing page
  traffic data and reindexing with a new schema.

  These issues are commented on in the code:

  > We need to switch the aliases without a lock, since
  > `read_only_allow_delete` prevents aliases being changed.
  >
  > The page traffic loader is is a daily process, so there won't be a
  > race condition.

  > We need to switch the aliases without a lock, since
  > `read_only_allow_delete` prevents aliases being changed.
  >
  > After running the schema migration, traffic must be represented
  > anyway, so the race condition is irrelevant.

- **Equivalent synonyms were not expanded.** We didn't figure out why
  this was happening, as the default configuration is to expand
  equivalent synonyms, and this configuration is not overrided.  The
  problem was fixed by turning all equivalent synonyms into explicit
  mappings.

- **Some queries would throw a bad request error during best bet
  analysis.** We also didn't figure out why this was happening.  It is
  possibly a problem with the Elasticsearch ruby library, as we were
  unsuccessful in replicating the problem when `curl`ing the cluster
  directly.  The problem was solved by handling the exception.


## Production teething problems

We encountered some issues after switching over production.  We
suspect that these had not been caught in staging because staging
doesn't have publishing activity, and also there is a possibility that
the traffic replay to staging had not been set to 100%.

Elasticsearch performance issues:

- **Queries queueing up in Elasticsearch.** We didn't realise that
  this was a problem at first, due to unfamiliarity with the new
  metrics.  We ended up doubling the size of the cluster and also
  switching to faster data nodes.

- **Long, slow, queries.** The slow query logs revealed that we were
  sometimes getting 3,000+ character queries which would take over a
  second each to execute.  We changed search-api to reject queries
  over 512 characters in length, and finder-frontend to truncate such
  queries.

  This was probably also a problem with Elasticsearch 2.

Elasticsearch errors:

- **Errors due to unmapped types being used for sorting.** Most
  queries are over multiple indices, but not all fields exist in all
  indices.  We saw many errors trying to sort by a field which was
  only present in the `govuk` index.  This was fine, as all the
  results were in the `govuk` index, but the errors were so frequent
  that they obscured any actual problems.  We changed the query
  search-api generates to include a default sort behaviour for missing
  fields, sorting them to the end.

  This was probably also a problem with Elasticsearch 2.

search-api performance issues:

- **Only two search machines (rather than three) had been
  provisioned.** The Terraform configuration for the AWS search
  machines only created two machines, whreas we had three in Carrenza.
  So search-api could only handle two thirds of the traffic of
  rummager.  We initially bumped the unicorn workers in each AWS
  search machine by half, and then added the missing third machine
  when we realised the problem.

- **Failing to generate the sitemap files.** The AWS search machines
  were running out of memory trying to generate sitemap files.  These
  were working at one point, but then stopped.  We changed the sitemap
  files to only have 25,000 links per file (rather than 50,000).  This
  revealed a bug we would have eventually hit anyway, where sitemap
  generation failed when there are 10 or more sitemap files.  That bug
  was fixed.


## Data sync for production -> staging -> integration

We use Elasticsearch snapshots for the data sync.

There are three snapshot repositories backed by S3 buckets:

- `govuk-production`, backed by `govuk-production-elasticsearch5-manual-snapshots`.
- `govuk-staging`, backed by `govuk-staging-elasticsearch5-manual-snapshots`.
- `govuk-integration`, backed by `govuk-integration-elasticsearch5-manual-snapshots`.

Elasticsearches write to and read from these repositories:

- Production *writes to* `govuk-production`.
- Staging *reads from* `govuk-production` and *writes to* `govuk-staging`.
- Integration *reads from* `govuk-staging` and *writes to* `govuk-integration`.

Sometimes staging writes a metadata file to the production bucket (and
integration writes a metadata file to the staging bucket).  This can't
be avoided, as Elasticsearch requires write access to a snapshot
repository even if it only ever restores snapshots, so we have a
Lambda to fix the object permissions when this happens.

Taking and restoring snapshots is triggered by the `govuk_env_sync`
script.

Terraform can provision the S3 buckets, but it can't tell
Elasticsearch about them.  This Python script does that:

```python
import os
import sys
import boto3
import requests
from requests_aws4auth import AWS4Auth

host = 'http://elasticsearch5/'
region = 'eu-west-1'
service = 'es'
credentials = boto3.Session().get_credentials()
awsauth = AWS4Auth(credentials.access_key, credentials.secret_key, region, service, session_token=credentials.token)

def register_repository(name, role_arn, delete_first=False):
    print(name)

    url = host + '_snapshot/' + name

    if delete_first:
        r = requests.delete(url)
        r.raise_for_status()
        print(r.text)

    payload = {
        "type": "s3",
        "settings": {
            "bucket": name + '-elasticsearch5-manual-snapshots',
            "region": region,
            "role_arn": role_arn
        }
    }

    headers = {"Content-Type": "application/json"}

    r = requests.put(url, auth=awsauth, json=payload, headers=headers)
    r.raise_for_status()
    print(r.text)

delete_first = 'DELETE_FIRST' in os.environ

if sys.argv[1] == 'integration':
    role_arn = 'arn:aws:iam::210287912431:role/blue-elasticsearch5-manual-snapshot-role'
    register_repository('govuk-integration', role_arn, delete_first=delete_first) # write
    register_repository('govuk-staging', role_arn, delete_first=delete_first) # read
elif sys.argv[1] == 'staging':
    role_arn = 'arn:aws:iam::696911096973:role/blue-elasticsearch5-manual-snapshot-role'
    register_repository('govuk-staging', role_arn, delete_first=delete_first) # write
    register_repository('govuk-production', role_arn, delete_first=delete_first) # read
elif sys.argv[1] == 'production':
    role_arn = 'arn:aws:iam::172025368201:role/blue-elasticsearch5-manual-snapshot-role'
    register_repository('govuk-production', role_arn, delete_first=delete_first) # write
else:
    print('expected one of [integration|staging|production]')
```


## Dockerising the development VM

We can't mange Elasticsearch 6 through Puppet, due to version
constraints.  Upgrading Puppet so we can upgrade eventually to
Elasticsearch 6 is far too much work, so we dockerised Elasticsearch 5
in the development VM.

The data replication process was changed to download the
`govuk-integration-elasticsearch5-manual-snapshots` S3 bucket, copy it
into the docker container, and restore the latest snapshot.


[PR #1439]: https://github.com/alphagov/search-api/pull/1439
[govuk-aws]: https://github.com/alphagov/govuk-aws
[govuk-aws-data]: https://github.com/alphagov/govuk-aws-data
[govuk-puppet]: https://github.com/alphagov/govuk-puppet
[licence-finder]: https://github.com/alphagov/licence-finder
[Set up a new Rails application]: https://docs.publishing.service.gov.uk/manual/setting-up-new-rails-app.html
[a large section on breaking changes]: https://www.elastic.co/guide/en/elasticsearch/reference/5.0/breaking-changes-5.0.html
[puppet-elasticsearch]: https://github.com/elastic/puppet-elasticsearch
[app-elasticsearch5]: https://github.com/alphagov/govuk-aws/tree/master/terraform/projects/app-elasticsearch5
[elasticsearch-migration-helpers]: https://github.com/alphagov/elasticsearch-migration-helpers/
[X-Ray]: https://aws.amazon.com/xray/
