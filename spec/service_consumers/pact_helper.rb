ENV["PACT_DO_NOT_TRACK"] = "true"
ENV["RACK_ENV"] = "test"

require "pact/provider/rspec"
require "webmock/rspec"
require "gds_api"

require_relative "../../spec/support/index_helpers"
require_relative "../../spec/support/integration_test_helper"

Pact.configure do |config|
  config.reports_dir = "spec/reports/pacts"
  config.include WebMock::API
  config.include WebMock::Matchers
  config.include IntegrationTestHelper
end

def pact_broker_base_url
  "https://govuk-pact-broker-6991351eca05.herokuapp.com"
end

Pact.service_provider "Search API" do
  include ERB::Util

  honours_pact_with "GDS API Adapters" do
    if ENV["PACT_URI"]
      pact_uri(ENV["PACT_URI"])
    else
      path = "pacts/provider/#{url_encode(name)}/consumer/#{url_encode(consumer_name)}"
      version_modifier = "versions/#{url_encode(ENV.fetch('PACT_CONSUMER_VERSION', 'branch-main'))}"
      pact_uri("#{pact_broker_base_url}/#{path}/#{version_modifier}")
    end
  end
end

Pact.provider_states_for "GDS API Adapters" do
  set_up do
    WebMock.enable!
    WebMock.reset!
    IntegrationTestHelper.allow_elasticsearch_connection_to_test(pact_broker_base_url)
    IndexHelpers.setup_test_indexes
  end

  tear_down do
    IndexHelpers.clean_all
    WebMock.disable!
  end

  provider_state "there are four search results for universal credit" do
    set_up do
      document_params = {
        "title" => "Universal credit 1",
        "link" => "/universal-credit-1",
      }
      second_document_params = {
        "title" => "Universal credit 2",
        "link" => "/universal-credit-2",
      }
      third_document_params = {
        "title" => "Universal credit 3",
        "link" => "/universal-credit-3",
      }
      fourth_document_params = {
        "title" => "Universal credit 4",
        "link" => "/universal-credit-4",
      }
      commit_document("government_test", document_params)
      commit_document("government_test", second_document_params)
      commit_document("government_test", third_document_params)
      commit_document("government_test", fourth_document_params)
    end
  end
end
