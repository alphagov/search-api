source "https://rubygems.org"

gem "activesupport", "~> 5.1.4"
gem "elasticsearch", "~> 2"
gem "gds-api-adapters", "~> 50.8"
gem "govuk_app_config", "~> 1.2.1"
gem "govuk_document_types", "~> 0.2.0"
gem "govuk-lint", "~> 3.5.0"
gem "logging", "~> 2.2.2"
gem "govuk_sidekiq", "~> 3.0.0"
gem "loofah"
gem "nokogiri", "~> 1.8.1"
gem "plek", "~> 2.0"
gem "rack", "~> 2.0"
gem "rack-logstasher", "~> 1.0.0"
gem "rake", "~> 12.3"
gem 'sidekiq-limit_fetch'
gem "sinatra", "~> 2.0.0"
gem "statsd-ruby", "~> 1.4.0"
gem "unf", "~> 0.1.4"
gem "whenever", "~> 0.10.0"

gem "govuk_message_queue_consumer", :git => 'https://github.com/alphagov/govuk_message_queue_consumer.git', :branch => 'process-batches-of-messages'

group :test do
  gem 'bunny-mock', '~> 1.7'
  gem 'govuk_schemas', '~> 3.1.0'
  gem 'govuk-content-schema-test-helpers', '~> 1.6.0'
  gem "rack-test", "~> 0.8.2"
  gem 'rspec'
  gem "simplecov", "~> 0.15.1"
  gem "simplecov-rcov", "~> 0.2.3"
  gem "timecop", "~> 0.9.1"
  gem "webmock", "~> 3.2.1"
end

group :development do
  # (Intelligent) reloading server in development
  gem "mr-sparkle", "0.3.0"
  gem "rainbow"
end

gem "pry-byebug", group: [:development, :test]
