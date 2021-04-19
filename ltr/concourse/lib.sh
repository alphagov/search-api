pip install -r search-api-git/ltr/concourse/requirements-freeze.txt

apt-get update
apt-get -y install jq

function assume_role {
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_SESSION_TOKEN
  unset AWS_DEFAULT_REGION

  aws sts assume-role --role-arn "$ROLE_ARN" --role-session-name "concourse-search-ltr" > aws-credentials

  # don't echo the credentials (even if they are temporary ones) to stdout
  AWS_ACCESS_KEY_ID="$(jq -r .Credentials.AccessKeyId < aws-credentials)"
  AWS_SECRET_ACCESS_KEY="$(jq -r .Credentials.SecretAccessKey < aws-credentials)"
  AWS_SESSION_TOKEN="$(jq -r .Credentials.SessionToken < aws-credentials)"
  AWS_DEFAULT_REGION=eu-west-1

  export AWS_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY
  export AWS_SESSION_TOKEN
  export AWS_DEFAULT_REGION
}
