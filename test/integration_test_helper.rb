require "test_helper"
require "app"
require "elasticsearch/search_server"
require "sidekiq/testing/inline" # Make all queued jobs run immediately
require "support/integration_test"
