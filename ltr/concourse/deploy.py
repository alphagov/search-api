#!/usr/bin/env python

import os
import sagemaker
import sagemaker.tensorflow
import sys
import time

govuk_environment = os.environ["GOVUK_ENVIRONMENT"]
role = os.environ["ROLE_ARN"]
model_name = os.environ["SCRIPT_INPUT_DATA"].strip()

s3_bucket = os.getenv("S3_BUCKET", f"govuk-{govuk_environment}-search-relevancy")
default_initial_instance_count = int(os.getenv("INITIAL_INSTANCE_COUNT", 3))
default_instance_type = os.getenv("INSTANCE_TYPE", "ml.t2.medium")
endpoint_name = os.getenv(
    "ENDPOINT_NAME", f"govuk-{govuk_environment}-search-ltr-endpoint"
)

session = sagemaker.Session()

initial_instance_count = default_initial_instance_count
instance_type = default_instance_type
update_endpoint = False

# try tofind the current endpoint config
try:
    current_endpoint_config_name = session.boto_session.client(
        "sagemaker"
    ).describe_endpoint(EndpointName=endpoint_name)["EndpointConfigName"]
    current_endpoint_config = session.boto_session.client(
        "sagemaker"
    ).describe_endpoint_config(EndpointConfigName=current_endpoint_config_name,)
    initial_instance_count = current_endpoint_config["ProductionVariants"][0][
        "InitialInstanceCount"
    ]
    instance_type = current_endpoint_config["ProductionVariants"][0]["InstanceType"]
    update_endpoint = True
except Exception:
    print("could not find current endpoint, will create a new one", file=sys.stderr)

# find the model
model_keys = session.boto_session.client("s3").list_objects_v2(
    Bucket=s3_bucket, Prefix=f"model/{model_name}"
)["Contents"]
if len(model_keys) != 1:
    raise Exception("Expected exactly 1 model key")
model_key = model_keys[0]["Key"]

# deploy the model by creating a new endpoint config and updating the
# existing endpoint (or creating a new one)
sagemaker.tensorflow.serving.Model(
    f"s3://{s3_bucket}/{model_key}", role, framework_version="2.0.0"
).deploy(
    initial_instance_count,
    instance_type,
    endpoint_name=endpoint_name,
    update_endpoint=update_endpoint,
)

# wait for the deployment to complete
endpoint_status = "Updating"
while endpoint_status in ["Creating", "Updating"]:
    print("Waiting for new model to be deployed...", file=sys.stderr)
    endpoint_status = session.boto_session.client("sagemaker").describe_endpoint(
        EndpointName=endpoint_name
    )["EndpointStatus"]
    time.sleep(10)

if endpoint_status != "InService":
    print(f"Unexpected endpoint status: {endpoint_status}", file=sys.stderr)
    sys.exit(1)

# remove the old endpoint config and model
session.boto_session.client("sagemaker").delete_endpoint_config(
    EndpointConfigName=current_endpoint_config_name,
)
session.boto_session.client("sagemaker").delete_model(
    ModelName=current_endpoint_config["ProductionVariants"][0]["ModelName"],
)

print("done", file=sys.stderr)
