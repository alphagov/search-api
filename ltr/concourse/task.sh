#!/usr/bin/env bash

set -euxo pipefail

source ltr/concourse/lib.sh

set +x
assume_role
set -x

SCRIPT_INPUT_DATA="${SCRIPT_INPUT_DATA:-}"

if [[ -z "$SCRIPT_INPUT_DATA" ]] && [[ -n "${INPUT_FILE_NAME:-}" ]]; then
  SCRIPT_INPUT_DATA=$(cat "${GOVUK_ENVIRONMENT}-${INPUT_FILE_NAME}/${GOVUK_ENVIRONMENT}-${INPUT_FILE_NAME}-"*".txt")
fi

export SCRIPT_INPUT_DATA

script="$1"
python "ltr/concourse/${script}.py" | tee script_output.txt

if [[ -n "${OUTPUT_FILE_NAME:-}" ]]; then
  tail -n1 script_output.txt > "out/${GOVUK_ENVIRONMENT}-${OUTPUT_FILE_NAME}-$(date +%s).txt"
fi
