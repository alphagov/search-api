require "test_helper"
require "app"
require "elasticsearch/search_server"
require "sidekiq/testing/inline"  # Make all queued jobs run immediately
require "support/elasticsearch_integration_helpers"
require "support/integration_fixtures"

class IntegrationTest < MiniTest::Unit::TestCase
  include Rack::Test::Methods
  include IntegrationFixtures
  include ElasticsearchIntegrationHelpers

  def app
    Rummager
  end

  def parsed_response
    JSON.parse(last_response.body)
  end

  def assert_document_is_in_rummager(document)
    retrieved = fetch_document_from_rummager(link: document['link'])

    document.each do |key, value|
      assert_equal value, retrieved[key],
        "Field #{key} should be '#{value}' but was '#{retrieved[key]}'"
    end
  end

  def assert_document_missing_in_rummager(link:)
    assert_raises RestClient::ResourceNotFound do
      fetch_document_from_rummager(link: link)
    end
  end

private

  def fetch_document_from_rummager(link:)
    elasticsearch_url = "http://localhost:9200/mainstream_test/edition/#{CGI.escape(link)}"
    raw_response = RestClient.get(elasticsearch_url)
    JSON.parse(raw_response)['_source']
  end
end
