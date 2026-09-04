# Decision record: Upgrading Elasticsearch 6.8 to OpenSearch 3.7

**Date:** 2026-09-03

## Context

Our current search infrastructure runs on AWS Managed Elasticsearch 6.8. We want to move to a newer search platform to keep the infrastructure current and benefit from improvements in newer releases.

Continuing to run an older version also increases operational risk, as support may eventually be discontinued and newly identified bugs or security issues may no longer receive fixes or patches.

## Possible Upgrade Paths

From the existing AWS Managed Elasticsearch 6.8 deployment, we considered three upgrade paths.

### 1. Upgrade to Elasticsearch 7.10

The most conservative option would be to upgrade from Elasticsearch 6.8 to Elasticsearch 7.10 first. This would minimise the version gap and reduce the immediate compatibility risk, as OpenSearch was forked from Elasticsearch 7.10.2.

### 2. Migrate to an Earlier OpenSearch Version

We could migrate to an earlier OpenSearch release, such as OpenSearch 1.x or 2.x. This would allow us to move away from Elasticsearch while reducing the version gap compared with OpenSearch 3.7.

### 3. Migrate Directly to OpenSearch 3.7

We could migrate directly from Elasticsearch 6.8 to OpenSearch 3.7. This has the largest version and platform gap, and therefore carries greater compatibility risk, but avoids an intermediate migration and provides a more current target platform. OpenSearch 3.7 is also the latest supported OpenSearch version available on AWS, making it the preferred long-term target.

## Decision

We will migrate directly from AWS Managed Elasticsearch 6.8 to OpenSearch 3.7, skipping Elasticsearch 7.10 and intermediate OpenSearch versions.

We accept the additional short-term risk of the larger migration in order to avoid multiple migrations and reach a more current platform in a single step.

## Evaluation

OpenSearch 3.7 was evaluated against Elasticsearch 6.8 using:

- **Traffic replay** to validate behaviour and performance under representative workloads.

- **Expanded integration tests** to validate application compatibility.

- **Example queries** to identify differences in query behaviour and results.

- **Relevance testing** to compare search result quality.

The testing confirmed that the Search API's functionality, search results, relevance, and performance remained as expected when running against OpenSearch 3.7.

## Consequences

### Positive

- Avoids an intermediate Elasticsearch or OpenSearch upgrade.

- Provides a more current OpenSearch baseline for future upgrades.

- Reduces the operational risk of remaining on Elasticsearch 6.8.

- Reduces the likelihood of requiring another major migration in the near future with all the associated risks.

### Negative

- The larger version and platform change carries greater migration risk.

- Some queries, APIs, or configuration may require adjustment where OpenSearch differs from Elasticsearch.

- As with any production migration, there is some residual risk that issues may only become apparent over longer-term production use.

## Risks and Mitigations

| Risk | Mitigation                                                                                        |
| --- |---------------------------------------------------------------------------------------------------|
| Application incompatibility | Expanded integration and example query testing.                                                   |
| Search relevance changes | Relevance testing against Elasticsearch 6.8.                                                      |
| Performance issues | Representative traffic replay.                                                                    |
| Unexpected production behaviour | Monitor closely after migration and maintain a rollback strategy using our blue-green deployment. |

## Status

**Accepted**