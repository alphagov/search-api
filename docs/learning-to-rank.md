Learning to Rank
================

We use a machine learning approach to improve search result relevance,
using the [TensorFlow Ranking][] module.  This doc covers how to use it,
and what additional work is required.

ADR-010 and ADR-011 cover the architectural decisions.

[TensorFlow Ranking]: https://github.com/tensorflow/ranking


Running it locally
------------------

### Set up

TensorFlow is written in Python 3, so you will need some libraries
installed.  The simplest way to do this is using `virtualenv`:

```sh
pip3 install virtualenv
virtualenv venv -p python3
source venv/bin/activate
pip install -r ltr/scripts/requirements-freeze.txt
```

This adjusts your shell's environment to use a local Python package
database in the `venv` directory.  If you close the shell, you can run
`source venv/bin/activate` again to bring everything back.


### Using LTR

**Set the `ENABLE_LTR` environment variable to "true", or all of this is disabled.**

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
govuk-docker run -e ENABLE_LTR=true search-api-lite bundle exec rake 'learn_to_rank:generate_training_dataset[judgements.csv]'
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
govuk-docker run -e ENABLE_LTR=true search-api-app
```

If you query search-api then results will be re-ranked when you order by
relevance.  If this doesn't happen, check you're running search-api with
`ENABLE_LTR` set.

You can disable re-ranking with the parameter `ab_tests=relevance:disable`.

The `learn_to_rank:reranker:evaluate` task can be used to compare
queries without needing to manually search for things.  It uses the
same `judgements.csv` file.

[govuk-secrets]: https://github.com/alphagov/govuk-secrets


Running it in production
------------------------

In production the model training and deployment are automated through
Jenkins, with the deployed model hosted in [Amazon SageMaker][].
The Jenkins job executes the script `ltr/jenkins/start.sh` and
runs on the [Deploy Jenkins][].

The Jenkins job has four tasks, one for each environment, which:

1. Spin up a EC2 instance and start an SSH session

2. Generate datasets to train a new model. It does this by running the Search
   API application locally in a container on the EC2 instance and calling the
   relevant rake tasks.

3. Call Amazon SageMaker's training API to create a new model from
   that training data, and store the model artefact in S3. This happens from
   the EC2 instance.

4. Call Amazon SageMaker's deployment API to deploy the new model,
   removing the old model configuration (but leaving the artefact in
   S3). This happens from the EC2 instance.

The Jenkins job for each environment is triggered automatically at 10pm on
Sundays. 

All artefacts are stored in the relevancy S3 bucket: training data is
under `data/<timestamp>/` and model data under `model/<training
timestamp>-<timestamp>`.  Files are removed by a lifecycle policy
after 7 days.

[Deploy Jenkins]: https://deploy.integration.publishing.service.gov.uk/job/search-api-learn-to-rank/
[Amazon SageMaker]: https://aws.amazon.com/sagemaker/

Reranking
---------

Reranking happens when `ENABLE_LTR=true` is set.  The model is found
by trying these options in order, going for the first one which
succeeds:

1. If `TENSORFLOW_SAGEMAKER_ENDPOINT` is set, [Amazon SageMaker][] is
   used.  It's assumed that search-api is running under a role which
   has permissions to invoke the endpoint.

2. If `TENSORFLOW_SERVING_IP` is set, `http:://<ip>::8501` is used.

3. If `RANK_ENV` is `development`, `http://reranker:8501` is used.

4. `http://0.0.0.0:8501` is used.

When reranking is working, search-api results get three additional
fields:

- `model_score`: the score assigned by TensorFlow
- `combined_score`: the score used for the final ranking
- `original_rank`: how Elasticsearch ranked the result

We may remove `combined_score` in the future, as it's just the same as
`model_score`.


Further work
-----

- Investigate window sizes for reranking (top-k)
- Reduce the performance impact of reranking
- Update the process for improving search relevance
