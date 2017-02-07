require "sinatra"
require_relative "env"
require "search_config"
require "config/logging_setup"
require "airbrake"

set :search_config, SearchConfig.new
set :default_index_name, "mainstream"

configure :development do
  set :protection, false
end

# Enable custom error handling (eg ``error Exception do;...end``)
# Disable fancy exception pages (but still get good ones).
disable :show_exceptions

initializers_path = File.expand_path("config/initializers/*.rb", File.dirname(__FILE__))

Dir[initializers_path].each { |f| require f }

configure do
  Airbrake.configuration.ignore << "Sinatra::NotFound"
  Airbrake.configuration.ignore << "LegacySearch::InvalidQuery"

  # We manually send `Indexer::BulkIndexFailure` to Airbrake with extra
  # parameters for debugging. Ignore it here so that we don't send them twice.
  Airbrake.configuration.ignore << "Indexer::BulkIndexFailure"

  # We manually send `GdsApi` exceptions to Airbrake with normalised
  # messages for publishing-api errors, and then raise an Indexer::PublishingApiError
  # exception to ensure the execution flow stops. Ignore it here so that we
  # don't send this dummy exception.
  Airbrake.configuration.ignore << "Indexer::PublishingApiError"

  use Airbrake::Sinatra
end
