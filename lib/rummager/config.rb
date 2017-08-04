require "sinatra"
require_relative "../../env"
require "rummager"

set :default_index_name, "mainstream"

configure :development do
  set :protection, false
end

# Enable custom error handling (eg ``error Exception do;...end``)
# Disable fancy exception pages (but still get good ones).
disable :show_exceptions

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

  # We catch this error and return a 400 response, however as a result of enabling
  # `raise_error` in the sinatra config this still tries to report to airbrake which
  # we don't want. This is a short term fix until we have a chance to make the config
  # more standard (disabling `raise_error` which is the default for production)
  Airbrake.configuration.ignore << "Search::Query::Error"

  use Airbrake::Sinatra
end
