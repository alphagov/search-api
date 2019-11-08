EXPORT_PATH="$(pwd)/tmp/libsvm/export/latest_exporter"
LATEST=`ls -1 $EXPORT_PATH | sort -hr | head -n 1`

# Start TensorFlow Serving container and open the REST API port
docker run -t --rm -p 8501:8501 \
    --network govuk-docker_default \
    --network-alias reranker \
    -v "$EXPORT_PATH/$LATEST:/models/ltr/1" \
    -e MODEL_NAME=ltr \
    tensorflow/serving
