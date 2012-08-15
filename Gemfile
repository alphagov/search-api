source :rubygems
source 'https://gems.gemfury.com/vo6ZrmjBQu5szyywDszE/'

group :router do
  gem 'router-client', '2.0.3', :require => 'router/client'
end

gem "unicorn"
gem "sinatra"
gem "delsolr", :git => "https://github.com/alphagov/delsolr.git"
gem 'rake', '0.9.2'
gem 'slimmer', '1.2.3'
gem 'erubis'
gem 'json'
gem 'activesupport', '~> 3.1.0'
gem 'i18n'
gem 'gds-api-adapters', '~> 0.0.48'
gem 'rack', '1.3.5'
gem 'plek', '0.1.23'
gem 'sinatra-content-for', '0.1'
gem 'aws-ses'


if ENV['GOVSPEAK_DEV']
  gem 'govspeak', path: '../govspeak'
else
  gem 'govspeak', '~> 0.8.15'
end

group :test do
  gem "simplecov"
  gem "simplecov-rcov"
  gem "ci_reporter"
  gem "test-unit"
  gem "rack-test"
  gem "nokogiri"
  gem "mocha", :require => false
  gem "webmock", :require => false
  gem "htmlentities"
end

group :development do
  gem "shotgun"
end
