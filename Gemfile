source "https://rubygems.org"

# We have been experiencing `ActiveSupport::Deprecation::MethodWrapper` errors
# when deploying versions of this app with activesupport 4.0.13. Pin to this
# version for now until we've upgraded other apps and fixed the issue.
gem "activesupport", "3.2.22.2"
gem "airbrake", "~> 4.3.6"
gem "elasticsearch", "~> 2"
gem "gds-api-adapters", "~> 41.2"
gem "govuk_document_types", "~> 0.1"
gem "govuk-lint", "~> 1.2.1"
gem "logging", "~> 2.1.0"
gem "loofah"
gem "nokogiri", "~> 1.7.2"
gem "plek", "~> 1.12"
gem "rack", "~> 2.0"
gem "rack-logstasher", "~> 1.0.0"
gem "rake", "~> 10.5"
gem "redis-namespace", "~> 1.5.2"
gem "sidekiq", "~> 4.1.2"
gem 'sidekiq-limit_fetch'
gem "sidekiq-statsd", "0.1.5"
gem "sinatra", "~> 2.0.0"
gem "slop", "~> 3.4.5"
gem "statsd-ruby", "~> 1.3.0"
gem "unf", "~> 0.1.4"
gem "unicorn", "5.1.0"
gem "whenever", "~> 0.9.4"

if ENV["MESSAGE_QUEUE_CONSUMER_DEV"]
  gem "govuk_message_queue_consumer", path: "../govuk_message_queue_consumer"
else
  gem "govuk_message_queue_consumer", "~> 3.0.2"
end

group :test do
  gem 'bunny-mock', '~> 1.7'
  gem "ci_reporter", "~> 1.7.1"
  gem 'govuk_schemas', '~> 2.2.0'
  gem "minitest", "~> 5.6.0"
  gem "mocha", "~> 1.1.0"
  gem "rack-test", "~> 0.6.3"
  gem "shoulda-context", "~> 1.2.1"
  gem "simplecov", "~> 0.10.0"
  gem "simplecov-rcov", "~> 0.2.3"
  gem "test-unit", "~> 3.0"
  gem "timecop", "~> 0.8.0"
  gem "webmock", "~> 1.24"
end

group :development do
  # (Intelligent) reloading server in development
  gem "mr-sparkle", "0.3.0"
end

gem "pry-byebug", group: [:development, :test]
