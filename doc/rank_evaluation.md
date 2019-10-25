# Rank evaluation

One way we assess the affect of search-api changes to relevancy, is by using
Elasticsearch's [Ranking Evaluation API](ranking_evaluation_api).

The API enables us to score how well search-api ranks results for a given query.

## What is rank evaluation?

Rank evaluation is a process by which we rate how well search-api ranks results for
a given query.

For example, given the query `Harry Potter` in an ideal situation, the results
would be returned in this order:

1. Harry Potter
2. Harry Potter World
3. Who is Harry Potter?

However, the results might come back in this order:

1. Who is Harry Potter?
2. Sign in to your HMRC account
3. Harry Potter

The first situation is good and the second is bad. But what we really
want is a metric to say *how bad* the results are.

Rank evaluation provides us with a metric which tells us how good or bad
the results are for a set of queries that we have already manually ranked.

So we have a rake task `debug:rank_evaluation` that does this.

This is useful, because we can tell how good a change is before running an
AB test on real users.

For example:

```
$ rake debug:rank_evaluation

harry potter:                      0.6297902553883483
passport:                          0.7926871059630242
contact:                           0.9957591943893841
...
Overall score:                     0.8209391842392532 (average of all scores)
```

The above means that the queries for `passport` and `contact` are both
returning better results than the query for `harry potter`.

Moreover, if the score for `harry potter` was `0.2392687105963024` before
we made a change, then that means we've made a good change for that query.

This can be measured over time, and it is! See the section on 'What do we do
with the query scores?' below.

## How do we compute a score for a query?

Given a set of queries and a list of manually rated documents, the API tells
us how well we are ranking the results of queries given the manual ratings
we have supplied.

A score of 1 is perfect and a score of 0 is catastrophic.

But how do we get to the number `0.6297902553883483` for the query `harry potter`?

We use [nDCG](ncdg) (normalised Discounted Cumulative Gain). DCG is a measure of ranking quality.

From Wikipedia:

By using DCG we make two assumptions:

> - Highly relevant documents are more useful when appearing earlier in a search engine result list (have higher ranks)
> - Highly relevant documents are more useful than marginally relevant documents, which are in turn more useful than non-relevant documents.

DCG requires a query and a list of relevancy judgements (rated documents).

We manually give a rating between 0 and 3 to documents in search results:

```
0 = irrelevant (which is equivalent to unrated in DCG)
1 = misplaced
2 = near
3 = relevant
```

For example, for the query `harry potter` we manually rate the documents in the
results:

```
QUERY             RATING  DOCUMENT
harry potter      2       Who is Harry Potter?
harry potter      0       Sign in to your HMRC account
harry potter      3       Harry Potter
harry potter      2       Harry Potter World
...
```

We then provide this to the Elasticsearch Rank Evaluation API, which behind the
scenes does a query for harry potter, and compares the ratings we provided with
what the actual results are, computes normalised DCG (number between 0 and 1)
and returns it to us. Thus `harry potter = 0.6297902553883483` at this moment
in time.

## What do we do with the query scores?

We use them for checking changes locally, as a quick check before we run an AB
test.

```
debug:rank_evaluation[my-local-relevancy-judgements.csv]
```

We also report the rank evaluation scores to graphite.
This enables us to plot how relevancy changes over time (overall
  and for a given query).

This runs every 3 hours in all environments:
```
SEND_TO_GRAPHITE=true debug:rank_evaluation
```

See the Search Relevancy grafana dashboard.

## How do we collect relevancy judgements?

We're working on that at the moment. So far we've manually generated them.

In future we could gather more internally in the organisation, or use end-user
click data as a signal for relevancy judgements.

Once we have relevancy judgements we upload them as a CSV to an S3 bucket,
which then gets pulled by search-api when the scheduled job runs.

[ranking_evaluation_api]: https://www.elastic.co/guide/en/elasticsearch/reference/6.7/search-rank-eval.html#search-rank-eval
[ncdg]: https://en.wikipedia.org/wiki/Discounted_cumulative_gain
