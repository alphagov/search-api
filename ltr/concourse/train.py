#!/usr/bin/env python

import os
import sagemaker
import sys
import time

govuk_environment = os.environ["GOVUK_ENVIRONMENT"]
image = os.environ["IMAGE"]
role = os.environ["ROLE_ARN"]
training_data = os.environ["SCRIPT_INPUT_DATA"].strip()

image_tag = os.getenv("IMAGE_TAG", "latest")
s3_bucket = os.getenv("S3_BUCKET", f"govuk-{govuk_environment}-search-relevancy")
instance_count = os.getenv("INSTANCE_COUNT", 1)
instance_size = os.getenv("INSTANCE_SIZE", "ml.c5.xlarge")

session = sagemaker.Session()

train_key = f"data/{training_data}/train.txt"
test_key = f"data/{training_data}/test.txt"
validate_key = f"data/{training_data}/validate.txt"

model_name = f"{training_data}-{str(time.time())}"

# train model
estimator = sagemaker.estimator.Estimator(
    f"{image}:{image_tag}",
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
