source "https://rubygems.org"

gem "activesupport", "~> 6.0.0"
gem "elasticsearch", "~> 6"
gem "gds-api-adapters", "~> 60.0"
gem 'google-api-client', '~> 0.30.10'
gem 'googleauth', '~> 0.9.0'
gem "govuk_app_config", "~> 2.0.0"
gem "govuk_document_types", "~> 0.9.2"
gem "govuk-lint", "~> 3.11.5"
gem "irb", "~> 1.0", require: false
gem "logging", "~> 2.2.2"
gem "govuk_sidekiq", "~> 3.0.3"
gem "loofah"
gem "oauth2"
gem "oj"
gem "nokogiri", "~> 1.10.4"
gem "plek", "~> 3.0"
gem "rack", "~> 2.0"
gem "rack-logstasher", "~> 1.0.1"
gem "rake", "~> 12.3"
gem 'sidekiq-limit_fetch'
gem "sinatra", "~> 2.0.7"
gem "statsd-ruby", "~> 1.4.0"
gem "unf", "~> 0.1.4"
gem "warden"
gem "warden-oauth2"
gem "whenever", "~> 1.0.0"

if ENV["MESSAGE_QUEUE_CONSUMER_DEV"]
  gem "govuk_message_queue_consumer", path: "../govuk_message_queue_consumer"
else
  gem "govuk_message_queue_consumer", "~> 3.5.0"
end

group :test do
  gem 'bunny-mock', '~> 1.7'
  gem 'climate_control', '~> 0.2'
  gem 'govuk_schemas', '~> 4.0.0'
  gem 'govuk-content-schema-test-helpers', '~> 1.6.1'
  gem "rack-test", "~> 1.1.0"
  gem 'rspec'
  gem "simplecov", "~> 0.17.0"
  gem "simplecov-rcov", "~> 0.2.3"
  gem "timecop", "~> 0.9.1"
  gem "webmock", "~> 3.7.4"
end

group :development do
  # (Intelligent) reloading server in development
  gem "mr-sparkle", "0.3.0"
  gem "rainbow"
end

gem "pry-byebug", group: [:development, :test]
