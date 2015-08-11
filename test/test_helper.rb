ENV['RACK_ENV'] = 'test'

# Simplecov should be required before any other code is loaded statement to prevent
# false negatives.
if ENV["USE_SIMPLECOV"]
  require "simplecov"
  require "simplecov-rcov"
  SimpleCov.start do
    add_filter '/test/'
  end

  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
end

$LOAD_PATH << File.expand_path('../../', __FILE__)
$LOAD_PATH << File.expand_path('../../lib', __FILE__)

require 'app'

require "bundler/setup"
require "minitest/autorun"
require 'turn/autorun'
require "rack/test"
require "mocha/setup"
require "fixtures/default_mappings"
require "pp"
require "shoulda-context"
require "logging"
require "timecop"

require "webmock/minitest"

# Prevent tests from messing with development/production data.
only_test_databases = %r{http://localhost:9200/(_search/scroll|_aliases|[a-z_-]+(_|-)test.*)}
WebMock.disable_net_connect!(allow: only_test_databases)

require "sample_config"
require "support/test_helpers"

class MiniTest::Unit::TestCase
  include TestHelpers
end

class ShouldaUnitTestCase < MiniTest::Unit::TestCase
  include Shoulda::Context::Assertions
  include Shoulda::Context::InstanceMethods
  extend Shoulda::Context::ClassMethods
end
