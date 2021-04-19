# LTR Scripts

This set of Learn To Rank scripts are for training, inspecting, and serving
a model with TensorFlow.

Train: Create a model with tf_ranking_libsvm.py that can be used to re-rank search results
Serve: Create a docker container to serve the trained model

## Set-up

Install python3 and virtualenv, then install the dependencies with:

```sh
virtualenv venv
source venv/bin/activate
pip install -r ltr/scripts/requirements-freeze.txt
```

You can now use the `ltr/scripts/train.sh` script to generate a model.

If you close your shell, run `source venv/bin/activate` again to set
up your python environment again.

## Usage

One can make requests directly to the served model with HTTP requests:

```sh
curl -X POST http://localhost:8501/v1/models/ltr:regress -d '{
  "signature_name": "regression",
  "examples": [
    {"1":0.0, "2":0.0, "3":0.0000001, "4":0.01000},
    {"1":0.0, "2":0.0, "3":0.0000002, "4":0.11000},
    {"1":0.0, "2":0.0, "3":0.0000002, "4":0.11000},
    {"1":0.0, "2":0.0, "3":0.0000002, "4":0.01000}
  ]
}'
```

If you don't want to serve the model, you can use `saved_model_cli` to
evaluate the model:

```sh
EXPORT_PATH="$(pwd)/tmp/libsvm/export/latest_exporter"
LATEST=`ls -1 $EXPORT_PATH | sort -hr | head -n 1`

saved_model_cli run \
--dir "$EXPORT_PATH/$LATEST" \
--tag_set serve \
--signature_def regression \
--input_examples 'examples=[
  {"1":0.0, "2":0.0, "3":0.0000001, "4":0.01000},
  {"1":0.0, "2":0.0, "3":0.0000002, "4":0.11000},
  {"1":0.0, "2":0.0, "3":0.0000002, "4":0.11000},
  {"1":0.0, "2":0.0, "3":0.0000002, "4":0.01000}
]'
```
