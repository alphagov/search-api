ENV["PACT_DO_NOT_TRACK"] = "true"

require "pact/provider/rspec"
require "webmock/rspec"
require "gds_api"

require_relative "../../spec/support/index_helpers"
require_relative "../../spec/support/integration_spec_helper"

Pact.configure do |config|
  config.reports_dir = "spec/reports/pacts"
  config.include WebMock::API
  config.include WebMock::Matchers
  config.include IntegrationSpecHelper
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
  set_up do
    WebMock.enable!
    WebMock.reset!
    IntegrationSpecHelper.allow_elasticsearch_connection_to_test(pact_broker_base_url)
    # need test environment index names
    stub_index_names if ENV["RACK_ENV"] == "development"
    IndexHelpers.setup_test_indexes
  end

  tear_down do
    IndexHelpers.clean_all
    WebMock.disable!
  end

  provider_state "there are search results for universal credit" do
    set_up do
      document_params = {
        "title" => "Universal credit",
        "link" => "/universal-credit",
      }
      commit_document("government_test", document_params)
    end
  end
end

def stub_index_names
  allow(SearchConfig).to receive(:content_index_names).and_return(%w[government_test])
  allow(SearchConfig).to receive(:govuk_index_name).and_return("govuk_test")
  allow(SearchConfig).to receive(:auxiliary_index_names).and_return(%w[page-traffic_test metasearch_test])
  allow(SearchConfig).to receive(:metasearch_index_name).and_return("metasearch_test")
  allow(SearchConfig).to receive(:registry_index).and_return("government_test")
  allow(SearchConfig).to receive(:page_traffic_index_name).and_return("page-traffic_test")
  allow(SearchConfig).to receive(:spelling_index_names).and_return(%w[government_test])
end
