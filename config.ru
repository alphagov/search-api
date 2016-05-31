app_path = File.dirname(__FILE__)
$:.unshift(app_path) unless $:.include?(app_path)

require "env"

require "bundler"
Bundler.require(:default, ENV['RACK_ENV'])

require "logger"

require "app"

in_development = ENV['RACK_ENV'] == 'development'

if in_development
  set :logging, $DEBUG ? Logger::DEBUG : Logger::INFO
else
  enable :logging
  log = File.new("log/production.log", "a")
  log.sync = true
  STDOUT.reopen(log)
  STDERR.reopen(log)

  use Rack::Logstasher::Logger,
    Logger.new("log/production.json.log"),
    extra_request_headers: { "GOVUK-Request-Id" => "govuk_request_id", "x-varnish" => "varnish_id" }
end

use GdsApi::GovukHeaderSniffer, 'HTTP_GOVUK_REQUEST_ID'
use GdsApi::GovukHeaderSniffer, 'HTTP_GOVUK_ORIGINAL_URL'

enable :dump_errors, :raise_errors

run Rummager
