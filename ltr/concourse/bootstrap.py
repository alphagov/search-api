#!/usr/bin/env python

import os
import sagemaker
import sagemaker.tensorflow

from datetime import date

govuk_environment = os.environ["GOVUK_ENVIRONMENT"]
role = os.environ["ROLE_ARN"]

s3_bucket = os.getenv("S3_BUCKET", f"govuk-{govuk_environment}-search-relevancy")
model = os.getenv("MODEL", "initial")
initial_instance_count = int(os.getenv("INITIAL_INSTANCE_COUNT", 3))
instance_type = os.getenv("INSTANCE_TYPE", "ml.t2.medium")
endpoint_name = os.getenv(
    "ENDPOINT_NAME", f"govuk-{govuk_environment}-search-ltr-endpoint"
)

sagemaker.tensorflow.serving.Model(f"s3://{s3_bucket}/model/{model}", role).deploy(
    initial_instance_count, instance_type, endpoint_name=endpoint_name
)

print("done")
