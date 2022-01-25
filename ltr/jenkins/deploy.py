#!/usr/bin/env python

import os
import sagemaker
import sagemaker.tensorflow
import sys
import time

govuk_environment = os.environ["GOVUK_ENVIRONMENT"]
role = os.environ["ROLE_ARN"]
model_name = os.getenv("MODEL_NAME")
s3_bucket = os.getenv("S3_BUCKET", f"govuk-{govuk_environment}-search-relevancy")

instance_count = int(os.getenv("DEPLOY_INSTANCE_COUNT"))
instance_type = os.getenv("DEPLOY_INSTANCE_TYPE")

endpoint_name = f"govuk-{govuk_environment}-search-ltr-endpoint"

session = sagemaker.Session()

update_endpoint = False

# try tofind the current endpoint config
try:
    current_endpoint_config_name = session.boto_session.client(
        "sagemaker"
    ).describe_endpoint(EndpointName=endpoint_name)["EndpointConfigName"]
    current_endpoint_config = session.boto_session.client(
        "sagemaker"
    ).describe_endpoint_config(EndpointConfigName=current_endpoint_config_name,)
    update_endpoint = True
except Exception:
    print("could not find current endpoint, will create a new one", file=sys.stderr)

# find the model

model_location_prefix = f"model/{model_name.strip()}/output"
print(f"looking with prefix {model_location_prefix}", file=sys.stderr)

try:
    model_keys = session.boto_session.client("s3").list_objects_v2(
        Bucket=s3_bucket, Prefix=model_location_prefix
    )["Contents"]
except KeyError:
    print(f"Couldn't find the model in {model_location_prefix}", file=sys.stderr)
    sys.exit(1)

if len(model_keys) != 1:
    print(f"Found too many models at {model_location_prefix}! Found models:", file=sys.stderr)
    for key in model_keys:
        print(f"- {key['Key']}", file=sys.stderr)
    sys.exit(1)

model_key = model_keys[0]["Key"]

print(f"Deploying model {model_key} to Sagemaker...", file=sys.stderr)

# Initialize boto3 Sagemaker client
# See the API Client docs:
# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/sagemaker.html
client = session.boto_session.client("sagemaker")

sagemaker_model_name = f"search-ltr-{str(time.strftime('%Y-%m-%d-%H-%M-%S'))}"
print(f"Model name will be: {sagemaker_model_name}.", file=sys.stderr)
print(f"Fetching model from s3://{s3_bucket}/{model_key}", file=sys.stderr)

# Upload trained model to Sagemaker
response = client.create_model(
    ModelName=sagemaker_model_name,
    PrimaryContainer={
        # See https://docs.aws.amazon.com/deep-learning-containers/latest/devguide/deep-learning-containers-images.html
        'Image': '763104351884.dkr.ecr.eu-west-1.amazonaws.com/tensorflow-inference:2.0.0-cpu',
        'Mode': 'SingleModel',
        'ModelDataUrl': f"s3://{s3_bucket}/{model_key}",
    },
    ExecutionRoleArn=role,
)

# A unique endpoint config is created for each model
new_endpoint_config_name = f"govuk-{govuk_environment}-{sagemaker_model_name}"

client.create_endpoint_config(
    EndpointConfigName=new_endpoint_config_name,
    ProductionVariants=[
        {
            'VariantName': 'primary',
            'ModelName': sagemaker_model_name,
            'InitialInstanceCount': instance_count,
            'InstanceType': instance_type
        },
    ]
)

# Update the Sagemaker endpoint to serve our new model (wrapped by the
# endpoint config)
response = client.update_endpoint(
    EndpointName=endpoint_name,
    EndpointConfigName=new_endpoint_config_name,
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
if update_endpoint:
    session.boto_session.client("sagemaker").delete_endpoint_config(
        EndpointConfigName=current_endpoint_config_name,
    )
    session.boto_session.client("sagemaker").delete_model(
        ModelName=current_endpoint_config["ProductionVariants"][0]["ModelName"],
    )

print("done", file=sys.stderr)
