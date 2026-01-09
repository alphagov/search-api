require "spec/support/index_helpers"
require "spec/support/integration_test_helper"

module IntegrationSpecSetupHelper
  def self.included(base)
    base.around do |example|
      IntegrationSpecSetupHelper.allow_connection_during_test do
        example.run
        # clean up after test run
        IndexHelpers.all_index_names.each do |index|
          clean_index_content(index)
        end
      end
    end

    # we only want to setup the before suite code once, in addition this this we only want to
    # set it up when we are running integration tests (hence the reason we do it here).
    @included ||= setup_before_suite
  end

  def self.setup_before_suite
    RSpec.configure do |config|
      config.before(:suite) do
        IntegrationSpecSetupHelper.allow_connection_during_test do
          IndexHelpers.setup_test_indexes
        end
      end

      config.after(:suite) do
        IntegrationSpecSetupHelper.allow_connection_during_test do
          IndexHelpers.clean_all
        end
      end
    end
  end

  def self.allow_connection_during_test
    IntegrationTestHelper.allow_elasticsearch_connection_to_test
    yield
  ensure
    IntegrationTestHelper.disable_net_connections
  end
end
