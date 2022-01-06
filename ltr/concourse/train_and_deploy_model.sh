set -euo pipefail

sudo apt-get update
sudo apt-get install -y awscli git

# docker setup from https://docs.docker.com/install/linux/docker-ce/ubuntu/
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io

cd /tmp
git clone --depth 1 --branch $GIT_BRANCH https://github.com/alphagov/search-api.git
cd search-api

pip install -r ltr/concourse/requirements-freeze.txt

docker_cmd="sudo docker run -v `pwd`:/work -v bundle:/usr/local/bundle -e ENABLE_LTR=true -e BIGQUERY_CREDENTIALS=`cat tmp/bigquery_creds.txt` -e ELASTICSEARCH_URI=$ELASTICSEARCH_URI -w /work --rm ruby:`cat .ruby-version`"

$docker_cmd bundle

mkdir tmp
echo "pulling data from bigquery"
$docker_cmd bundle exec rake 'learn_to_rank:fetch_bigquery_export[bigquery]'
aws s3 cp tmp/bigquery.csv s3://$S3_BUCKET/data/$NOW/bigquery.csv

echo "generating relevance judgements"
$docker_cmd bundle exec rake 'learn_to_rank:generate_relevancy_judgements[tmp/bigquery.csv,judgements]'
aws s3 cp tmp/judgements.csv s3://$S3_BUCKET/data/$NOW/judgements.csv

echo "Generating NDCG test data from top queries"
# Magic number based on top 1000 search terms from past 6 months
$docker_cmd bundle exec rake 'learn_to_rank:fetch_bigquery_export[bigquery_small,2000]'
$docker_cmd bundle exec rake 'learn_to_rank:generate_relevancy_judgements[tmp/bigquery_small.csv,autogenerated_judgements]'
aws s3 cp tmp/autogenerated_judgements.csv s3://$S3_BUCKET/autogenerated_judgements.csv

echo "generating training dataset"
$docker_cmd bundle exec rake 'learn_to_rank:generate_training_dataset[tmp/judgements.csv,svm]'
aws s3 cp svm/train.txt    s3://$S3_BUCKET/data/$NOW/train.txt
aws s3 cp svm/test.txt     s3://$S3_BUCKET/data/$NOW/test.txt
aws s3 cp svm/validate.txt s3://$S3_BUCKET/data/$NOW/validate.txt

echo "training the model"
python "ltr/concourse/train.py" > tmp/model_name.txt

# Deploy model
export MODEL_NAME=`cat tmp/model_name.txt`
python "ltr/concourse/deploy.py"
