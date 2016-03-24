source "https://rubygems.org"

gem "unicorn", "5.0.1"
gem "sinatra", "1.3.4"
gem "rake", "~> 10.5"
gem "rack", "~> 1.6"
gem "rest-client", "1.8.0"
gem "logging", "2.1.0"
gem 'nokogiri', "1.6.7.2"
gem 'whenever', require: false
gem "slop", "4.3.0"
gem "sidekiq", "4.1.1"
gem "sidekiq-statsd", "0.1.5"
# pin to version that includes security vulnerability fix
gem "redis-namespace", "1.5.2"
gem "plek", "1.12.0"
gem "gds-api-adapters", "~> 30.0"
gem "rack-logstasher", "0.0.3"
gem 'airbrake', '4.0.0'
gem "unf", "0.1.4"
gem 'aws-sdk', '~> 2.2.29'
gem 'elasticsearch', '~> 1.0.15'

group :test do
  gem "shoulda-context"
  gem "simplecov", "~> 0.11.2"
  gem "simplecov-rcov"
  gem 'turn', require: false # Pretty printed test output
  gem "ci_reporter", "1.7.1"
  gem "minitest", "4.6.1"
  gem "rack-test"
  gem "mocha", require: false
  gem "webmock", "~> 1.24"
  gem "timecop", "0.8.0"
end

group :development do
  # (Intelligent) reloading server in development
  gem "mr-sparkle", "0.3.0"
end

gem "govuk_message_queue_consumer", "~> 2.0.1"
gem "govuk-lint", "~> 0.8.1"
