source "https://rubygems.org"

gem "activesupport", "~> 6.0.2"
gem "aws-sdk-s3", "~> 1.60"
gem "aws-sdk-sagemakerruntime", "~> 1.18"
gem "elasticsearch", "~> 6"
gem "gds-api-adapters", "~> 63.2"
gem "google-api-client", "~> 0.36.3"
gem "google-cloud-bigquery", "~> 1.18.0"
gem "googleauth", "~> 0.10.0"
gem "govuk_app_config", "~> 2.0.1"
gem "govuk_document_types", "~> 0.9.2"
gem "govuk_sidekiq", "~> 3.0.5"
gem "irb", "~> 1.2", require: false
gem "logging", "~> 2.2.2"
gem "loofah"
gem "nokogiri", "~> 1.10.7"
gem "oauth2"
gem "oj"
gem "plek", "~> 3.0"
gem "rack", "~> 2.0"
gem "rack-logstasher", "~> 1.0.1"
gem "rake", "~> 13.0"
gem "rubocop-govuk"
gem "rubyzip", "2.0.0"
gem "sidekiq-limit_fetch"
gem "sinatra", "~> 2.0.7"
gem "statsd-ruby", "~> 1.4.0"
gem "unf", "~> 0.1.4"
gem "warden"
gem "warden-oauth2"

if ENV["MESSAGE_QUEUE_CONSUMER_DEV"]
  gem "govuk_message_queue_consumer", path: "../govuk_message_queue_consumer"
else
  gem "govuk_message_queue_consumer", "~> 3.5.0"
end

group :test do
  gem "bunny-mock", "~> 1.7"
  gem "climate_control", "~> 0.2"
  gem "govuk-content-schema-test-helpers", "~> 1.6.1"
  gem "govuk_schemas", "~> 4.0.0"
  gem "rack-test", "~> 1.1.0"
  gem "rspec"
  gem "simplecov", "~> 0.17.1"
  gem "simplecov-rcov", "~> 0.2.3"
  gem "timecop", "~> 0.9.1"
  gem "webmock", "~> 3.7.6"
end

group :development do
  # (Intelligent) reloading server in development
  gem "mr-sparkle", "0.3.0"
  gem "rainbow"
end

gem "pry-byebug", group: %i[development test]

gem "httparty", "~> 0.17.3"
