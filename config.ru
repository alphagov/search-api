app_path = File.dirname(__FILE__)
$LOAD_PATH.unshift(app_path) unless $LOAD_PATH.include?(app_path)

require "env"

require "bundler"
Bundler.require(:default, ENV["RACK_ENV"])

require "logger"

$LOAD_PATH << "./lib"
require "rummager/app"

in_development = ENV["RACK_ENV"] == "development"
log_path = ENV.fetch("LOG_PATH", in_development ? nil : "log/production.log")

if in_development
  set :logging, Logger::DEBUG
end

if log_path
  enable :logging
  unless ENV["LOG_TO_STDOUT"].present?
    log = File.new(log_path, "a")
    log.sync = true
    STDOUT.reopen(log)
    STDERR.reopen(log)
  end
end

unless in_development
  logger = ENV["LOG_TO_STDOUT"].present? ? Logger.new($stdout) : Logger.new("log/production.json.log") 
  use Rack::Logstasher::Logger,
      logger,
      extra_request_headers: { "GOVUK-Request-Id" => "govuk_request_id", "x-varnish" => "varnish_id" }
end

require "gds_api/middleware/govuk_header_sniffer"
use GdsApi::GovukHeaderSniffer, "HTTP_GOVUK_REQUEST_ID"
use GdsApi::GovukHeaderSniffer, "HTTP_GOVUK_ORIGINAL_URL"

enable :dump_errors, :raise_errors

run Rummager
