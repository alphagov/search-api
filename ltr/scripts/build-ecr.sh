#!/usr/bin/env bash

set -e

ECR_REPOSITORY="${1:-}"
TAG="${2:-latest}"

if [[ -z "$ECR_REPOSITORY" ]]; then
  echo "usage: $0 <ecr repository url> [tag]"
  echo
  echo "  the tag defaults to 'latest'"
  exit 1
fi

if [[ ! -e Dockerfile.sagemaker ]]; then
  echo "run this script in the search-api/ltr/scripts directory"
  exit 1
fi

if [[ -z "${AWS_ACCESS_KEY_ID:-}" ]]; then
  echo "AWS environment variables not found: run this after assuming a role."
  exit 2
fi

$(aws ecr get-login --no-include-email --region eu-west-1)
docker build -t "${ECR_REPOSITORY}:${TAG}" -f Dockerfile.sagemaker .
docker push "${ECR_REPOSITORY}:${TAG}"
