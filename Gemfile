source "https://rubygems.org"

gem "activesupport"
gem "aws-sdk-s3"
gem "aws-sdk-sagemaker"
gem "aws-sdk-sagemakerruntime"
gem "bootsnap", require: false
gem "elasticsearch", "~> 7" # We need a 7.x release to interface with Elasticsearch 6 and 7
gem "gds-api-adapters"
gem "google-api-client"
gem "googleauth"
gem "google-cloud-bigquery"
gem "govuk_app_config"
gem "govuk_document_types"
gem "govuk_message_queue_consumer"
gem "govuk_schemas"
gem "govuk_sidekiq"
gem "httparty"
gem "irb", require: false
gem "logging"
gem "loofah"
gem "nokogiri"
gem "oauth2"
gem "oj", "3.11.3"
gem "plek"
gem "rack"
gem "rack-logstasher"
gem "rainbow"
gem "rake"
gem "rubyzip"
gem "sentry-sidekiq"
gem "sidekiq-limit_fetch"
gem "sinatra"
gem "statsd-ruby"
gem "unf"
gem "warden"
gem "warden-oauth2"

group :development, :test do
  gem "pry-byebug"
  gem "rubocop-govuk", require: false
end

group :development do
  gem "mr-sparkle"
end

group :test do
  gem "bunny-mock"
  gem "climate_control"
  gem "rack-test"
  gem "rspec"
  gem "simplecov"
  gem "timecop"
  gem "webmock"
end
