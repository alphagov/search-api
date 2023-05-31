from deploy import deploy
from train import train

import os

govuk_environment = os.environ["GOVUK_ENVIRONMENT"]

s3_bucket = os.environ["AWS_S3_RELEVANCY_BUCKET_NAME"]
role = os.environ["ROLE_ARN"]
image = os.environ["IMAGE"]

train_instance_count = int(os.getenv("TRAIN_INSTANCE_COUNT"))
train_instance_type = os.getenv("TRAIN_INSTANCE_TYPE")

deploy_instance_count = int(os.getenv("DEPLOY_INSTANCE_COUNT"))
deploy_instance_type = os.getenv("DEPLOY_INSTANCE_TYPE")

model_name = train(s3_bucket, image, role, train_instance_count, train_instance_type)

deploy(model_name, s3_bucket, role, govuk_environment, deploy_instance_count, deploy_instance_type)
