EXPORT_PATH="$(pwd)/tmp/libsvm/export/latest_exporter"
LATEST=`ls -1 $EXPORT_PATH | sort -hr | head -n 1`

saved_model_cli run \
--dir "$EXPORT_PATH/$LATEST" \
--tag_set serve \
--signature_def regression \
--input_examples 'examples=[
  { "1": [0.0000719424], "2": [0.0040773314], "3": [0.0494675737], "4": [2988417670.0], "5": [176401570.0], "6": [99999.0000000000], "7": [230202.0000000000], "8": [0.0000000000] },
  { "1": [0.0000017889], "2": [0.0005870092], "3": [0.0498584460], "4": [0.2986949700], "5": [0.0000000000], "6": [0222.0000000000], "7": [0.0000000000], "8": [0.0000000000] },
]'
