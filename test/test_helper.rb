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

ELASTICSEARCH_TESTING_HOST = ENV.fetch('ELASTICSEARCH_TESTING_HOST', 'http://localhost:9200')

# load this first to avoid duplicate constant declaration error
require 'logging'
require 'health_check/logging_config'

require 'rummager'
require 'rummager/app' # load the website

require "minitest/autorun"
# Add colourful test output. This works in development but not in CI.
require "minitest/pride" unless ENV["JENKINS_URL"]

require "bundler/setup"
require "rack/test"
require "mocha/setup"
require "pp"
require "shoulda-context"
require "timecop"
require "pry-byebug"
require "govuk_schemas"

require "webmock/minitest"

# Silence log output
Logging.logger.root.appenders = nil
Sidekiq::Logging.logger = nil

# Prevent tests from messing with development/production data.
only_test_databases = %r{#{ELASTICSEARCH_TESTING_HOST}/(_search/scroll|_aliases|_bulk|[a-z_-]+(_|-)test.*)}
WebMock.disable_net_connect!(allow: only_test_databases)

require "support/default_mappings"
require "support/test_helpers"
require "support/hash_including_helpers"
require "support/schema_helpers"

require "gds_api/test_helpers/publishing_api_v2"

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
