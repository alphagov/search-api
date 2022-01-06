#!/usr/bin/env bash
set -ex

find_instance_id() {
  aws ec2 describe-instances --region "$AWS_REGION" --query "Reservations[*].Instances[*].InstanceId" --filters Name=instance-state-name,Values=running,pending  Name=tag:Name,Values="$EC2_NAME" --output=text
}

EC2_NAME="govuk-${GOVUK_ENVIRONMENT}-search-ltr-generation"
AWS_REGION="eu-west-1"

echo "Scaling up ASG..."
aws autoscaling set-desired-capacity \
    --region "$AWS_REGION" \
    --auto-scaling-group-name "$EC2_NAME" \
    --desired-capacity 1

instance_id=$(find_instance_id)
while [[ "$instance_id" == "" ]]; do
  echo "    still waiting for instance ID..."
  sleep 30
  instance_id=$(find_instance_id)
done

echo "Waiting on instance ${instance_id}..."
aws ec2 wait instance-status-ok \
    --region "$AWS_REGION" \
    --instance-ids "${instance_id}"

instance_hostname=$(aws ec2 describe-instances --region "$AWS_REGION" --query "Reservations[*].Instances[*].PrivateDnsName" --filter Name=tag:Name,Values="$EC2_NAME" --output=text)

echo "Connecting to instance..."
scp -i ${SSH_PRIVATE_KEY_PATH} -o StrictHostKeyChecking=no <(echo -n "$BIGQUERY_CREDENTIALS") "ubuntu@${instance_hostname}:tmp/bigquery_creds.txt"

ssh -i ${SSH_PRIVATE_KEY_PATH} -o StrictHostKeyChecking=no "ubuntu@${instance_hostname}" env \
  NOW="$(date +%s)" \
  GOVUK_ENVIRONMENT=$GOVUK_ENVIRONMENT \
  GIT_BRANCH="deployed-to-${GOVUK_ENVIRONMENT}" \
  ROLE_ARN=$ROLE_ARN \
  S3_BUCKET="govuk-${GOVUK_ENVIRONMENT}-search-relevancy" \
  IMAGE=$IMAGE \
  TRAIN_INSTANCE_TYPE=$TRAIN_INSTANCE_TYPE \
  TRAIN_INSTANCE_COUNT=$TRAIN_INSTANCE_COUNT \
  DEPLOY_INSTANCE_TYPE=$DEPLOY_INSTANCE_TYPE \
  DEPLOY_INSTANCE_COUNT=$DEPLOY_INSTANCE_COUNT \
  ELASTICSEARCH_URI=$ELASTICSEARCH_URI \
  'bash -s' < ./ltr/concourse/train_and_deploy_model.sh

echo "Scaling down ASG..."
aws autoscaling set-desired-capacity \
    --region "$AWS_REGION" \
    --auto-scaling-group-name "$EC2_NAME" \
    --desired-capacity 0
