OUTPUT_DIR=./tmp/libsvm && \
TRAIN=./tmp/ltr_data/train.txt && \
VALI=./tmp/ltr_data/validate.txt && \
TEST=./tmp/ltr_data/test.txt

rm -rf $OUTPUT_DIR && \
python3 ./tf_ranking_libsvm.py \
--train_path=$TRAIN \
--vali_path=$VALI \
--test_path=$TEST \
--output_dir=$OUTPUT_DIR \
--num_features=6 \
--num_train_steps=10000
