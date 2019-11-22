# Decision record: Learning To Rank

**Date:** 2019-11-07

The search team have decided to implement [Learning To Rank][].

1. What is Learning To Rank?
1. Motivation
1. Implementation
1. What success will look like

[Learning To Rank]: https://en.wikipedia.org/wiki/Learning_to_rank

## What is Learning To Rank?

Learning To Rank (LTR) is the application of machine learning to create a
ranking model that can be used to improve search relevance.

This is a common approach for advanced search applications.

The ranking of search results on websites is frequently determined by
machine learning models. For example, Airbnb, Yelp, Wikipedia, Bloomberg,
and commercial search engines.

There is a good explanation on what LTR is here:

- https://elasticsearch-learning-to-rank.readthedocs.io/en/latest/core-concepts.html
- https://opensourceconnections.com/blog/2017/02/24/what-is-learning-to-rank/

### How does Learning To Rank work?

It's easiest to explain with an example:

Say you searched for 'Harry Potter'. Search API might return the following results:

1. HMRC Sign in
2. Harry Potter World
3. Pottery barn
4. Harry Potter

These are not good results.

To assess search quality, we can assign relevancy judgements to the
results of a query in the range 0-3, with 0 being irrelevant and 3
being perfect. For example, for these results:

```
query         rating    document
harry potter  0         HMRC Sign in
harry potter  2         Harry Potter World
harry potter  0         Pottery barn
harry potter  3         Harry Potter
```

We can then use a ranking quality metric, such as [normalised
discounted cumulative gain (nDCG)](https://en.wikipedia.org/wiki/Discounted_cumulative_gain#Normalized_DCG) to assign a score to
this list of results.

We can then use nDCG to tell us how good the results are.
We might get a score of 0.3 for this result set (from 0 to 1).

We could then investigate why the results are bad. Perhaps there is a
best bet. Or popularity might be pushing HMRC docs up. We can fix these
things, then check the new nDCG score, and we might get 0.7 for this query.

In contrast, with Learning To Rank, search result ranks would be
determined by a machine learning model without manually changing
the boost of a field.

With Learning To Rank we would go through the same process of
rating the search results.

```
harry potter  0         Pottery barn
harry potter  3         Harry Potter
...
```

However, after doing this, we would train a model with this data
to rank the results better. The model optimises for nDCG.

We train the model using a combination of relevancy judgements
and features: numeric measures which indicate how well we think the
result matches the query.

The text similarity scores Elasticsearch assigns to fields in the
document are examples of features. The model tries to find correlations
between document features and relevancy judgements, which allows it to
predict how to order documents we don't have relevancy judgements for.

```
query         rating    document      title_score view_count  recency  pagerank ...
harry potter  0         Pottery barn  0.2         9876        0.12     9876     ...
harry potter  3         Harry Potter  0.2         1234        1234     1234     ...
...
```

For example, take the training dataset below for the query 'harry potter' (qid:1)

```
0 qid:1 popularity:0.3 title_score:0.2 description_score:0.3 recency:0.9 pagerank:5 ...
3 qid:1 popularity:0.1 title_score:0.6 description_score:0.7 recency:0.5 pagerank:2 ...
```

> **Note**: This format is frequently used for Learning To Rank training
> datasets, including the TensorFlow ranking library.
> [Details on the format](https://sourceforge.net/p/lemur/wiki/RankLib%20File%20Format).

These graded query:document pairs and their features can be used
to train a model.

The model might learn that title and description scores are slightly
more useful that popularity and recency, and how much, in certain
circumstances.

Rather than manually tuning boosts, a model learns from relevancy
judgements the role that features should play when providing relevant results.

This is a high level overview of what Learning To Rank is for our use case.
There has been a lot of research in this area, and within the fields of
information retrieval & machine learning which Learning To Rank intersects.
There is a lot more out there to learn!

For more details about how we plan to implement Learning To Rank, see
the implementation section below.

## Motivation

We have decided to try Learning To Rank because it has the potential
to greatly improve search relevance in a way that is:

- automatable
- scalable
- more maintainable
- more successful

**Automatable** because the model won't require human involvement to
tune field boosts on the latest user data

**Scalable** because automation; but also because the model should
provide better results with more data.

**Maintainable** because relevancy tuning can be automated to not become
stale.

**Successful** because results should achieve higher nDCG scores and
click-through rates than we can achieve through manual tuning alone.

### The problem

Manual relevancy tuning can work, but doesn't scale well. Eventually
the process becomes a game of whack-a-mole. If we downgrade popularity
boosting, then this query might have better results, but other queries
might have worse results.

Hand-tuning relevance doesn't work very well because field boosts
are complex, and difficult to maintain.

Moreover field boosts might have dependencies: some document types might
benefit from a stronger title boost than other document types, for
instance. Expressing that just with Elasticsearch would be prohibitively
complex, and be almost impossible to maintain.

### Validating Learning To Rank

We assumed that we would be able to get better results using Learning
To Rank. To validate this assumption, we worked on a spike.

In a [validation spike][] we found that we could build a model that provided
a better nDCG score than our current search algorithm for the queries we
have manually gathered relevancy judgements for.

This validated for us that Learning To Rank is feasible and could
lead to more relevant results for users.

Though Learning To Rank won't make relevance tuning easier, it could
make search results more relevant.

### Final decision

We feel confident about implementing Learning To Rank (LTR) for the
following reasons:

- We think that it will improve search relevancy for citizens, enabling
  them to find what they need on GOV.UK
- We have validated our assumptions with a spike
- LTR is a well trodden path, and other organisations have written about
  their implementations with varying levels of openness (e.g. Wikimedia)
- GOV.UK has implemented other machine learning projects with success
  (related links, topic taxonomy), and we have a data science team which
  the search team has already worked with
- TensorFlow provides an off-the-shelf ranking module, which solves
  some of the machine learning problems of LTR for us
- Manual relevancy tuning is not scalable, and won't get us to the same
  level of relevancy as LTR

## Implementation plan

We have decided to implement Learning To Rank by following on from
the work started in the [validation spike][].

As we are at the beginning of the project, this section may not
accurately reflect the final implementation.

[validation spike]: https://github.com/alphagov/search-api/pull/1768

### Machine learning library

We have decided to use [TensorFlow's ranking library][] for our
implementation of Learning To Rank.

TensorFlow is well supported, and the ranking library is under active development.

We considered using the [elasticsearch-learning-to-rank][] plugin.
However, AWS Elasticsearch does not permit us to install custom plugins.

We also considered PyTorch. However, this would require writing much more
custom machine learning code, as PyTorch don't currently have a ranking library.

[TensorFlow's ranking library]: https://github.com/tensorflow/ranking
[elasticsearch-learning-to-rank]: https://github.com/o19s/elasticsearch-learning-to-rank

### Further decisions

We have further decisions to make around the following areas, which may
be the subject of further ADRs:

- language: divide between ruby and python
- hosting the trained model (dockerised?)
- training data pipeline architecture
- where does compute-intensive training happen?
- failure resilience (what happens when reranker process fails? should we backup datasets, models?)
- monitoring and alerts
- testing/validating the model
- how would LTR change local development?

## What success will look like

Success will look like:

- Click-through rate on the top 3 and top 5 results will go up
- nDCG will go up
- Search latency will not increase much

Before we can deploy the model it must provide a better CTR and nDCG.

A further hope for this project is that we will be able to remove
some complexity by deleting the boosting code in Search API.
