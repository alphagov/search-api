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
require "pp"
require "shoulda-context"
require "logging"
require "timecop"
require "pry"

require "webmock/minitest"

# Prevent tests from messing with development/production data.
only_test_databases = %r{http://localhost:9200/(_search/scroll|_aliases|[a-z_-]+(_|-)test.*)}
WebMock.disable_net_connect!(allow: only_test_databases)

require "support/default_mappings"
require "support/test_helpers"
require "support/hash_including_helpers"
require "support/schema_helpers"

class MiniTest::Unit::TestCase
  include TestHelpers
  include HashIncludingHelpers
  include SchemaHelpers
end

class ShouldaUnitTestCase < MiniTest::Unit::TestCase
  include Shoulda::Context::Assertions
  include Shoulda::Context::InstanceMethods
  extend Shoulda::Context::ClassMethods
end
