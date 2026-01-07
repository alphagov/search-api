ENV["PACT_DO_NOT_TRACK"] = "true"

require "pact/provider/rspec"
require "webmock/rspec"
require "gds_api"
# require ::File.expand_path("../../config/environment", __dir__) # not a rails app so no equivalent file
# require "gds_api/test_helpers/search" TODO: Do we need?

# require_relative "../../app/services/search_api_fields" TODO: do we need?
# require_relative "../../spec/support/organisations_api_test_helper" TODO: do we need?
# require_relative "../../spec/support/search_api_helpers" TODO: do we need?
require_relative "../../spec/support/integration_spec_helper"
require_relative "../../spec/support/index_helpers"

Pact.configure do |config|
  config.reports_dir = "spec/reports/pacts"
  config.include WebMock::API
  config.include WebMock::Matchers
  # config.include OrganisationsApiTestHelper TODO: do we need?
  # config.include SearchApiHelpers TODO: do we need?
  # config.include SearchApiFields TODO: do we need?
  # config.include GdsApi::TestHelpers::Search TODO: do we need?
  config.include IntegrationSpecHelper
  config.include IndexHelpers
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
      version_modifier = "versions/#{url_encode(ENV.fetch('PACT_CONSUMER_VERSION', 'master'))}"
      pact_uri("#{pact_broker_base_url}/#{path}/#{version_modifier}")
    end
  end
end

Pact.provider_states_for "GDS API Adapters" do
  # set_up do
  #   WebMock.enable!
  #   WebMock.reset!
  # end

  # tear_down do
  #   WebMock.disable!
  # end

  provider_state "there are search results for universal credit" do
    set_up do
      # want to use elasticsearch test indexes - think this is automatic from use of methods
      # commit document to test search index - I think this index is empty to start with
      document_params = {
        "title" => "Universal credit",
        "link" => "/universal-credit",
      }
      commit_document("government_test", document_params)
      # retrieve that document via a get request (in pact test in gds-api-adapters)
    end
  end
end
