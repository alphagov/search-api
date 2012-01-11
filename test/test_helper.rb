ENV['RACK_ENV'] = 'test'

require "test/unit"
require "rack/test"
%w[ . lib ].each do |path|
  $:.unshift path unless $:.include?(path)
end
require "mocha"

require "webmock/test_unit"
WebMock.disable_net_connect!

require "simplecov"
require "simplecov-rcov"
SimpleCov.start
SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter

require "response_assertions"

require "helpers"
class TestHelper
  include Helpers
end
