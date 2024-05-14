# Decision record: Decommissioning Learning to Rank

**Date:** 2024-05-14

The search team have decided to retire [Learning to Rank][] (LTR).

## Rationale

[Site search][] now uses Google's Vertex AI search instead of our ElasticSearch + Learning to Rank service. The other finders still use ElasticSearch and LTR. Site Search receives more requests than all the other finders combined.

Running our own relevance tuning service on top of ElasticSearch is not something we are equipped to do at this time, particularly when it's in support of a vastly reduced demand.

It's expensive to do well, both in terms of money spent on infrastructure and the time that the appropriate people would need to devote to it. Unfortunately, we just don't have that available.

### Limited upside to retaining it

Learning to Rank was configured primarily for Site Search and the general features of documents on GOV.UK. Other finders are often set up for small sets of specific document types. These documents have many features for which Learning to Rank has not been trained.

The model is poorly suited to differentiating between different Employment Tribunal decisions, for example.

### Limited impact to removing it

Our implementation of Learning to Rank always had a limited "blast radius" in that if would only be able to affect the rankings of a single page of results at a time. The biggest impact it could have on a result would be to promote the 20th result to be 1st (and vice versa).

This also means that there is limited downside to removing the reranking feature. All the results for each query still appear on the same page as before, but potentially in a different order.

### Unaffected use cases

Learning to Rank only affected queries which included keywords and were ordered by relevance. Other queries, such as those that power organisation, taxon and topical event pages are unaffected.


[Site search]: https://www.gov.uk/search/all
[Learning to Rank]: https://github.com/alphagov/search-api/blob/1524da75f055f144392facb460bd95ef62b67bbb/docs/arch/adr-010-learn-to-rank.md
