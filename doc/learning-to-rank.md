Learning to Rank
================

We are trying out using machine learning for improving ranking, using
the [TensorFlow Ranking][] module.  This doc covers how to use it and
what further work there is to do before we can trial this as an A/B
test.  ADR-010 covers the architectural decisions.

[TensorFlow Ranking]: https://github.com/tensorflow/ranking


Set up
------

TensorFlow is written in Python 3, so you will need some libraries
installed.  The simplest way to do this is using `virtualenv`:

```sh
virtualenv venv -p python3
source venv/bin/activate
pip install -r ltr_scripts/requirements.txt
```

This adjusts your shell's environment to use a local Python package
database in the `venv` directory.  If you close the shell, you can run
`source venv/bin/activate` again to bring everything back.


Using LTR
---------

**Set the `ENABLE_LTR` environment variable, or all of this is disabled.**

There are several rake tasks for training and serving a TensorFlow
model in the `learn_to_rank` namespace.

The `learn_to_rank:generate_relevancy_judgements` task needs the
`GOOGLE_PRIVATE_KEY` and `GOOGLE_CLIENT_EMAIL` environment variables
set.  Values for these can be found in [govuk-secrets][].  The task is
run regularly and the generated `judgements.csv` file available in:

- `govuk-integration-search-relevancy`
- `govuk-staging-search-relevancy`
- `govuk-production-search-relevancy`

In the future we will store more things in these buckets, like the
trained models.

Assuming you have a `judgements.csv` file, you can generate a dataset
for training the model:

```sh
bundle exec rake learn_to_rank:generate_training_dataset[judgements.csv]
```

This task needs to be run with access to Elasticsearch.  If you're
using govuk-docker the full command will be:

```sh
govuk-docker run -e ENABLE_LTR=1 search-api-lite bundle exec rake 'learn_to_rank:generate_training_dataset[judgements.csv]'
```

Once you have the training dataset you can train and serve a model:

```sh
bundle exec rake learn_to_rank:reranker:train
bundle exec rake learn_to_rank:reranker:serve
```

These tasks do not need access to Elasticsearch.

You now have a docker container running and responding to requests
inside the govuk-docker network at `reranker:8501`.  You can start
search-api with the `ENABLE_LTR` environment variable with:

```sh
govuk-docker run -e ENABLE_LTR=1 search-api-app
```

If you now query search-api with `ab_tests=relevance:B` then results
will be re-ranked when you order by relevance.  If this doesn't
happen, check you're running search-api with `ENABLE_LTR` set.

The `learn_to_rank:reranker:evaluate` task can be used to compare
queries without needing to manually search for things.  It uses the
same `judgements.csv` file.

[govuk-secrets]: https://github.com/alphagov/govuk-secrets


Reranking
---------

When reranking is working, search-api results get three additional
fields:

- `model_score`: the score assigned by TensorFlow
- `combined_score`: the score used for the final ranking
- `original_rank`: how Elasticsearch ranked the result

In the future `combined_score` may just be `model_score` (in which
case it's likely to be removed from the response).


To do
-----

Here are problems to solve before we could turn this into an A/B test:

- Generate relevancy judgements from user data
- Investigate which features work best for modelling
- Investigate which TensorFlow settings work best for  modelling
- Investigate window sizes for reranking
- Measure the performance impact
- Schedule the training
- Store trained models in S3 and fetch the latest model for serving
- Handle errors in the reranker (eg, unavailability)
- Add monitoring and alerting
- Think about ways in which a black-box model could be abused and how we can debug issues
