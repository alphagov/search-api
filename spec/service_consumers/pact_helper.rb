ENV["PACT_DO_NOT_TRACK"] = "true"

require "pact/provider/rspec"
require "webmock/rspec"
require "gds_api"

require_relative "../../spec/support/index_helpers"

Pact.configure do |config|
  config.reports_dir = "spec/reports/pacts"
  config.include WebMock::API
  config.include WebMock::Matchers
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
    allow_elasticsearch_connection_to_test(pact_broker_base_url)
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

def allow_elasticsearch_connection_to_test(pact_broker_base_url)
  allowed_hosts = Clusters.active.map(&:uri)

  allowed_paths = []
  allowed_paths << "[a-z_-]+[_-]test.*"
  allowed_paths << "_alias"
  allowed_paths << "_bulk"
  allowed_paths << "_reindex"
  allowed_paths << "_search/scroll"
  allowed_paths << "_tasks"

  allow_urls = %r{#{allowed_hosts.map { |host| "#{host}/(#{allowed_paths.join('|')})" }.join('|')}}

  WebMock.disable_net_connect!(allow: [allow_urls, pact_broker_base_url])
end

def insert_document(index_name, attributes, id: nil, type: "edition", version: nil)
  version_details =
    if version
      {
        version:,
        version_type: "external",
      }
    else
      {}
    end

  atts = attributes.symbolize_keys

  id ||= atts[:link] || "/test/#{SecureRandom.uuid}"
  atts[:document_type] ||= type
  atts[:link] ||= id

  Clusters.active.each do |cluster|
    client(cluster:).index(
      {
        index: index_name,
        id:,
        type: "generic-document",
        body: atts,
      }.merge(version_details),
    )
  end

  id
end

def commit_document(index_name, attributes, id: nil, type: "edition")
  atts = attributes.symbolize_keys
  id ||= atts[:link]

  return_id = insert_document(index_name, atts, id:, type:)
  commit_index(index_name)
  return_id
end

def commit_index(index_name)
  Clusters.active.each do |cluster|
    client(cluster:).indices.refresh(index: index_name)
  end
end

def client(cluster: Clusters.default_cluster)
  # Set a fairly long timeout to avoid timeouts on index creation on the CI
  # servers
  Services.elasticsearch(cluster:, timeout: 10)
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
