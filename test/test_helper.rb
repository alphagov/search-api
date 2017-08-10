ENV['RACK_ENV'] = 'test'
require 'pry'

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

require "minitest/autorun"
# Add colourful test output. This works in development but not in CI.
require "minitest/pride" unless ENV["JENKINS_URL"]

require "bundler/setup"
require "rack/test"
require "mocha/setup"
require "pp"
require "shoulda-context"
require "logging"
require "timecop"

require "webmock/minitest"

# Silence log output
Logging.logger.root.appenders = nil

# Prevent tests from messing with development/production data.
only_test_databases = %r{http://localhost:9200/(_search/scroll|_aliases|[a-z_-]+(_|-)test.*)}
WebMock.disable_net_connect!(allow: only_test_databases)

require "support/default_mappings"
require "support/test_helpers"
require "support/hash_including_helpers"
require "support/schema_helpers"

class Minitest::Test
  include TestHelpers
  include HashIncludingHelpers
  include SchemaHelpers
end

class ShouldaUnitTestCase < Minitest::Test
  include Shoulda::Context::Assertions
  include Shoulda::Context::InstanceMethods
  extend Shoulda::Context::ClassMethods
end
