ENV['RACK_ENV'] = 'test'

$LOAD_PATH << File.expand_path('../../', __FILE__)
$LOAD_PATH << File.expand_path('../../lib', __FILE__)

require "bundler/setup"
require "test/unit"
require "rack/test"
require "mocha"
require "fixtures/default_mappings"
require 'pp'

require "webmock/test_unit"
WebMock.disable_net_connect!

if ENV["USE_SIMPLECOV"]
  require "simplecov"
  require "simplecov-rcov"
  SimpleCov.start
  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
end