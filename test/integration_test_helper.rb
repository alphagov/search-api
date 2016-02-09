require "test_helper"
require "app"
require "elasticsearch/search_server"
require "sidekiq/testing/inline"  # Make all queued jobs run immediately
require "support/integration_test"
require "support/index_document_test_helpers"
