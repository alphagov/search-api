source "https://rubygems.org"
source "https://BnrJb6FZyzspBboNJzYZ@gem.fury.io/govuk/"

gem "unicorn", "4.3.1"
gem "sinatra", "1.3.4"
gem "rake", "0.9.2", :require => false
gem "json", "1.7.7"
gem "multi_json", "1.3.6"
gem "yajl-ruby", "1.1.0"
gem "activesupport", "3.2.12"
gem "rack", "1.5.2"
gem "aws-ses", "0.4.4"
gem "rest-client", "1.6.7"
gem "statsd-ruby", "1.0.0"
gem "logging", "1.8.1"
gem "nokogiri", "1.5.5"
gem "whenever", require: false

group :test do
  gem "simplecov"
  gem "simplecov-rcov"
  gem "ci_reporter", "1.7.1"
  gem "minitest", "4.6.1"
  gem "rack-test"
  gem "mocha", :require => false
  gem "webmock", "1.9.3", :require => false
end

group :development do
  gem "shotgun"
  # Use thin because WEBrick sometimes segfaults
  gem "thin"
end
