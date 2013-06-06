ENV['RACK_ENV'] = 'test'

$LOAD_PATH << File.expand_path('../../', __FILE__)
$LOAD_PATH << File.expand_path('../../lib', __FILE__)

require "bundler/setup"
require "minitest/autorun"
require "rack/test"
require "mocha/setup"
require "fixtures/default_mappings"
require "pp"
require "shoulda-context"
require "logging"

require "webmock/minitest"
WebMock.disable_net_connect!

if ENV["USE_SIMPLECOV"]
  require "simplecov"
  require "simplecov-rcov"
  SimpleCov.start
  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
end

module TestHelpers
  def load_yaml_fixture(filename)
    YAML.load_file(File.expand_path("fixtures/#{filename}", File.dirname(__FILE__)))
  end
end

class MiniTest::Unit::TestCase
  include TestHelpers
end

class ShouldaUnitTestCase < MiniTest::Unit::TestCase
  include Shoulda::Context::Assertions
  include Shoulda::Context::InstanceMethods
  extend Shoulda::Context::ClassMethods
end
