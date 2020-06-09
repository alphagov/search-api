# Decision record: Sagemaker

**Date:** 2020-03-18

The search team have decided to use [AWS Sagemaker][] for training
and serving models for [Learning to Rank][].

## Before Sagemaker

Our initial infrastructure for Learning to Rank looked like this:

- Models were trained ad-hoc on local machines.
- To serve the models each search machine hosted a TensorFlow Serving docker
container, which search-api would call.

It looked like this:

```
                                 +-------------------+
                                 |                   |
                                 |  Locally-trained  |
                                 |       model       |
                                 |                   |
                                 +-------------------+
                                           |
+----------------------------------------------------------+
| Search machine                           |               |
|                                          |               |
|    +-----------------+       +-----------v----------+    |
|    |                 |       |                      |    |
|    |    Search API   +------->   Docker container   |    |
|    |                 <-------+ (TensorFlow Serving) |    |
|    |                 |       |                      |    |
|    +-----------------+       +----------------------+    |
|                                                          |
|                                                          |
+----------------------------------------------------------+
```

## After Sagemaker

After introducing Sagemaker, our infrastructure for training
and serving models does not use Docker and all training and
serving is done in AWS.

- Both models training and serving is done by AWS Sagemaker
  instances
- Search API reranks search results by making requests to a
  Sagemaker endpoint
- To create new models, we trigger changes to Sagemaker from
  a [Concourse][] pipeline.
- New models are trained in AWS Sagemaker spot instances.

```
                               +------------------------------+
    +----------------+         | AWS Sagemaker                |
    | External model |         |                              |
    | build trigger  +----+    |   +----------------------+   |
    |  (Concourse)   |    |    |   |                      |   |
    +----------------+    +-------->  Sagemaker training  |   |
                               |   |                      |   |
+---------------------------+  |   +---------+------------+   |
| Search machine            |  |             |                |
|                           |  |             |                |
|    +------------------+   |  |   +---------v----------+     |
|    |                  |   |  |   |                    |     |
|    |    Search API    +----------> Sagemaker endpoint |     |
|    |                  <----------+    (TF serving)    |     |
|    |                  |   |  |   |                    |     |
|    +------------------+   |  |   +--------------------+     |
|                           |  |                              |
|                           |  |                              |
+---------------------------+  +------------------------------+
```

From Search API's perspective, nothing has changed. It still
makes a call to an endpoint which then re-ranks results.

However, externally, Docker is no longer running on search machines,
and the reranking is performed on a different machine.

Rather than orchestrating model changes on search machines,
a Concourse pipeline handles the process of creating training data,
and training and serving models.

## Downsides

This new architecture has some downsides:

- the search architecture is more complicated, involving more machines
- we now have a bigger AWS bill, since we have to pay for Sagemaker
instances
- Search API requests to Sagemaker instances are considerably slower
than request to local docker containers, and potentially less reliable
- We are further locked into AWS infrastructure

However, we didn't feel these were too bad.

The architecture is not sufficiently complicated that we couldn't
manage it. Running docker on search machines was potentially going
to be trickier to manage than running these on separate machines.

For example, scaling up is much easier with SageMaker than docker.

The cost was not very high. We get greater control over our costs,
because training is done on spot instances which cost very little.

Sagemaker requests were not prohibitively slow. Requests to the docker
container took about 4ms, whereas to Sagemaker they take ~25ms.
There are slower parts of search requests that we can optimise first.

## Benefits

Using Sagemaker made it easier to train and serve new models.

Specifically:

- It's possible to serve many models at the same time for AB testing.
- We can scale sagemaker instances separately from Search API
instances.
- We can train and deploy new models on a schedule
- It's easier to train and experiment with models, as there is no need for a locally running TensorFlow / Search API / Elasticsearch.
- Deploying is simpler.

Other more general benefits:

- We get the benefits of AWS monitoring and alerts out of the box.
- We are using Sagemaker elsewhere (Data Labs team) so this will help
to ensure that our usage of ML is consistent.
- Sagemaker is a large suite of products, most of which we don't use,
but may want to in the future.
- Likewise, we may move from Jenkins to Concourse in future so this is
a nice step towards that.

## Still to do

- Add more documentation.
- Performing data jobs on spot instances. Training data is still generated on search machines.

[AWS Sagemaker]: https://aws.amazon.com/sagemaker/
[Learning to Rank]: https://github.com/alphagov/search-api/blob/1524da75f055f144392facb460bd95ef62b67bbb/docs/arch/adr-010-learn-to-rank.md
[Concourse]: https://concourse-ci.org/
