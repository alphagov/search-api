require "test_helper"
require 'sidekiq/testing'
require "sidekiq/testing/inline" # Make all queued jobs run immediately
require "support/integration_test"
require 'support/test_index_helpers'
require 'bunny-mock'
require 'govuk_schemas'

TestIndexHelpers.setup_test_indexes
