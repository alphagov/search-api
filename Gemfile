source :rubygems
source 'https://gems.gemfury.com/vo6ZrmjBQu5szyywDszE/'

group :router do
  gem 'router-client', '2.0.3', :require => 'router/client'
end

gem "unicorn"
gem "sinatra"
gem "delsolr", :git => "https://github.com/alphagov/delsolr.git"
gem 'rake', '0.9.2', :require => false
gem 'json'
gem 'activesupport', '~> 3.1.0'
gem 'i18n'
gem 'rack', '1.3.5'
gem 'plek', '0.1.23'
gem 'aws-ses'
gem 'rest-client', '1.6.7'

group :test do
  gem "simplecov"
  gem "simplecov-rcov"
  gem "ci_reporter"
  gem "test-unit"
  gem "rack-test"
  gem "mocha", :require => false
  gem "webmock", :require => false
  gem "nokogiri", :require => false
end

group :development do
  gem "shotgun"
end
