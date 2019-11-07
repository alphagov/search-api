require "sinatra"
require "rummager"

configure :development do
  set :protection, false
end

# Enable custom error handling (eg ``error Exception do;...end``)
# Disable fancy exception pages (but still get good ones).
disable :show_exceptions

Raven.configure do |config|
  config.excluded_exceptions << "Sinatra::NotFound"

  # We manually send `Indexer::BulkIndexFailure` to Sentry with extra
  # parameters for debugging. Ignore it here so that we don't send them twice.
  config.excluded_exceptions << "Indexer::BulkIndexFailure"

  # We manually send `GdsApi` exceptions to Sentry with normalised
  # messages for publishing-api errors, and then raise an Indexer::PublishingApiError
  # exception to ensure the execution flow stops. Ignore it here so that we
  # don't send this dummy exception.
  config.excluded_exceptions << "Indexer::PublishingApiError"

  # We catch this error and return a 400 response, however as a result of enabling
  # `raise_error` in the sinatra config this still tries to report to Sentry which
  # we don't want. This is a short term fix until we have a chance to make the config
  # more standard (disabling `raise_error` which is the default for production)
  config.excluded_exceptions << "Search::Query::Error"

  use Raven::Rack
end

Encoding.default_external = "UTF-8"
Encoding.default_internal = "UTF-8"
