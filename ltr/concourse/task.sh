#!/usr/bin/env bash

set -euxo pipefail

pip install -r search-api-git/ltr/concourse/requirements.txt

if [[ -n "${ROLE_ARN:-}" ]]; then
  apt-get update
  apt-get -y install jq

  aws sts assume-role --role-arn "$ROLE_ARN" --role-session-name "concourse-search-ltr" > aws-credentials

  # don't echo the credentials (even if they are temporary ones) to stdout
  set +x
  AWS_ACCESS_KEY_ID="$(jq -r .Credentials.AccessKeyId < aws-credentials)"
  AWS_SECRET_ACCESS_KEY="$(jq -r .Credentials.SecretAccessKey < aws-credentials)"
  AWS_SESSION_TOKEN="$(jq -r .Credentials.SessionToken < aws-credentials)"
  AWS_DEFAULT_REGION=eu-west-1

  export AWS_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY
  export AWS_SESSION_TOKEN
  export AWS_DEFAULT_REGION
  set -x
fi

SCRIPT_INPUT_DATA="${SCRIPT_INPUT_DATA:-}"

if [[ -z "$SCRIPT_INPUT_DATA" ]] && [[ -n "${INPUT_FILE_NAME:-}" ]]; then
  SCRIPT_INPUT_DATA=$(cat "${GOVUK_ENVIRONMENT}-${INPUT_FILE_NAME}/${GOVUK_ENVIRONMENT}-${INPUT_FILE_NAME}-"*".txt")
fi

export SCRIPT_INPUT_DATA

script="$1"
python "search-api-git/ltr/concourse/${script}.py" | tee script_output.txt

if [[ -n "${OUTPUT_FILE_NAME:-}" ]]; then
  tail -n1 script_output.txt > "out/${GOVUK_ENVIRONMENT}-${OUTPUT_FILE_NAME}-$(date +%s).txt"
fi
