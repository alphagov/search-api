source "https://rubygems.org"

gem "activesupport"
gem "aws-sdk-s3"
gem "aws-sdk-sagemaker"
gem "aws-sdk-sagemakerruntime"
gem "bootsnap"
gem "elasticsearch", "~> 6" # We need a 6.x release to interface with Elasticsearch 6
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
gem "oj"
gem "plek"
gem "rack"
gem "rack-logstasher"
gem "rainbow"
gem "rake"
gem "rubyzip"
gem "sidekiq-limit_fetch"
gem "sinatra"
gem "statsd-ruby"
gem "unf"
gem "warden"
gem "warden-oauth2"

group :development, :test do
  gem "pry-byebug"
  gem "rubocop-govuk", "4.0.0", require: false # Trialling pre-release
end

group :development do
  gem "mr-sparkle"
end

group :test do
  gem "bunny-mock"
  gem "climate_control"
  gem "govuk-content-schema-test-helpers"
  gem "rack-test"
  gem "rspec"
  gem "simplecov"
  gem "timecop"
  gem "webmock"
end
