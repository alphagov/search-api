source "https://rubygems.org"

gem "unicorn", "4.6.2"
gem "raindrops", "0.11.0"
gem "sinatra", "1.3.4"
gem "rake", "0.9.2", :require => false
gem "json", "1.7.7"
gem "multi_json", "1.3.6"
gem "yajl-ruby", "1.1.0"
gem "rack", "1.5.2"
gem "rest-client", "1.6.7"
gem "logging", "1.8.1"
gem 'nokogiri', "1.5.5"
gem 'whenever', require: false
gem 'ffi-aspell', "0.0.3"
gem "slop", "3.4.5"
gem "sidekiq", "2.13.0"
# pin to version that includes security vulnerability fix
gem "redis-namespace", "1.3.1"
gem "plek", "1.5.0"
gem "gds-api-adapters", "7.18.0"
gem "rack-logstasher", "0.0.3"
gem 'airbrake', '4.0.0'
gem "unf", "0.1.3"

group :test do
  gem "shoulda-context"
  gem "simplecov"
  gem "simplecov-rcov"
  gem 'turn', require: false # Pretty printed test output
  gem "ci_reporter", "1.7.1"
  gem "minitest", "4.6.1"
  gem "rack-test"
  gem "mocha", :require => false
  gem "webmock", "1.9.3", :require => false
end

group :development do
  # (Intelligent) reloading server in development
  gem "mr-sparkle", "0.2.0"
end

gem "pry", group: [:development, :test]
