ENV["RACK_ENV"] = "test"
require "pry"

require "simplecov"
SimpleCov.start { add_filter "/spec/" }

$LOAD_PATH << File.expand_path("..", __dir__)
$LOAD_PATH << File.expand_path("../lib", __dir__)

# load this first to avoid duplicate constant declaration error
require "logging"

require "rummager"
require "rummager/app" # load the website

require "bundler/setup"
require "climate_control"
require "rack/test"
require "pp"
require "timecop"
require "pry-byebug"

require "govuk_sidekiq/testing"
require "sidekiq/testing/inline" # Make all queued jobs run immediately
require "bunny-mock"
require "govuk_schemas"
require "govuk-content-schema-test-helpers"
require "govuk-content-schema-test-helpers/validator"

# Silence log output
Logging.logger.root.appenders = nil
Sidekiq::Logging.logger = nil

require "webmock/rspec"

require "#{__dir__}/support/default_mappings"
require "#{__dir__}/support/learn_to_rank_explain"
require "#{__dir__}/support/spec_helpers"
require "#{__dir__}/support/schema_helpers"
require "#{__dir__}/support/integration_spec_helper"
require "#{__dir__}/support/index_helpers"

require "gds_api/test_helpers/publishing_api"

RSpec.configure do |config|
  config.define_derived_metadata(file_path: %r{/spec/integration/}) do |metadata|
    metadata[:tags] ||= []
    metadata[:tags] << :integration
  end

  config.include SpecHelpers
  config.include SchemaHelpers

  config.include IntegrationSpecHelper, tags: :integration
  config.include Rack::Test::Methods, tags: :integration

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  # config.warnings = true

  config.before do
    # search_config is a global object that has state, while most of the stubbing
    # is automatically reset, the index_names or passed into children object and
    # cached there.
    Cache.clear
    Services.cache.clear
  end

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end
  config.profile_examples = 3

  config.order = :random
  Kernel.srand config.seed
end
