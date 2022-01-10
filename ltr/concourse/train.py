#!/usr/bin/env python

import os
import sagemaker
import sys
import time

govuk_environment = os.environ["GOVUK_ENVIRONMENT"]
image = os.environ["IMAGE"]
role = os.environ["ROLE_ARN"]
data_timestamp = os.environ["NOW"].strip()

s3_bucket = os.getenv("S3_BUCKET", f"govuk-{govuk_environment}-search-relevancy")
instance_count = os.getenv("INSTANCE_COUNT", 1)
instance_size = os.getenv("INSTANCE_SIZE", "ml.c5.xlarge")

session = sagemaker.Session()

train_key = f"data/{data_timestamp}/train.txt"
test_key = f"data/{data_timestamp}/test.txt"
validate_key = f"data/{data_timestamp}/validate.txt"

model_name = f"{data_timestamp}-{str(time.time())}"

# train model
estimator = sagemaker.estimator.Estimator(
    f"{image}:latest",
    role,
    instance_count,
    instance_size,
    output_path=f"s3://{s3_bucket}/model/{model_name}",
    sagemaker_session=session,
    disable_profiler=True
)

estimator.fit(
    inputs={
        "train": f"s3://{s3_bucket}/{train_key}",
        "test": f"s3://{s3_bucket}/{test_key}",
        "validate": f"s3://{s3_bucket}/{validate_key}",
    }
)

with open('./model_name.txt', 'w') as file:
    file.write(f"{model_name}/{estimator._current_job_name}")
