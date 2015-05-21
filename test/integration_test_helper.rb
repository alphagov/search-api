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

private

  def deep_copy(hash)
    Marshal.load(Marshal.dump(hash))
  end
end
