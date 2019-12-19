#!/usr/bin/env bash

OUTPUT_DIR=${OUTPUT_DIR:-../tmp/libsvm}
TRAIN=${TRAIN:-../tmp/ltr_data/train.txt}
VALI=${VALI:-../tmp/ltr_data/validate.txt}
TEST=${TEST:-../tmp/ltr_data/test.txt}
STEPS=${STEPS:-100000} # runs at ~1,000 rounds per minute. 50,000 steps = 50 mins.

if [[ -d $OUTPUT_DIR ]]; then
  rm -rf $OUTPUT_DIR
fi

python3 "$(dirname "$0")/tf_ranking_libsvm.py" \
--train_path=$TRAIN \
--vali_path=$VALI \
--test_path=$TEST \
--output_dir=$OUTPUT_DIR \
--num_features=16 \
--num_train_steps=$STEPS
