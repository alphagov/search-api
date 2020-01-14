#!/usr/bin/env bash

OUTPUT_DIR=${OUTPUT_DIR:-../tmp/libsvm}
TRAIN=${TRAIN:-../tmp/ltr_data/train.txt}
VALI=${VALI:-../tmp/ltr_data/validate.txt}
TEST=${TEST:-../tmp/ltr_data/test.txt}
STEPS=${STEPS:-100000} # runs at ~1,000 rounds per minute. 50,000 steps = 50 mins.

if [[ -d /opt/ml ]]; then
  # echo to stderr so it shows up in the log streamed to concourse
  echo "Training under SageMaker..." >&2

  # documentation says there should be environment variables with
  # these values in, but based on the output of `env`, that is a lie.
  TRAIN=/opt/ml/input/data/train/train.txt
  VALI=/opt/ml/input/data/validate/validate.txt
  TEST=/opt/ml/input/data/test/test.txt
  OUTPUT_DIR=/opt/ml/model
fi

if [[ ! -f "$TRAIN" ]]; then
  echo "Training data '$TRAIN' missing" >&2
  exit 1
fi

if [[ ! -f "$VALI" ]]; then
  echo "Validation data '$VALI' missing" >&2
  exit 1
fi

if [[ ! -f "$TEST" ]]; then
  echo "Test data '$TEST' missing" >&2
  exit 1
fi

if [[ -d "$OUTPUT_DIR" ]]; then
  pushd "$OUTPUT_PATH"
  rm -rf .
  popd
fi

python3 "$(dirname "$0")/tf_ranking_libsvm.py" \
--train_path="$TRAIN" \
--vali_path="$VALI" \
--test_path="$TEST" \
--output_dir="$OUTPUT_DIR" \
--num_features=16 \
--num_train_steps="$STEPS"
