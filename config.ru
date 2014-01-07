app_path = File.dirname(__FILE__)
$:.unshift(app_path) unless $:.include?(app_path)

# Raindrops is only loaded when running under Unicorn so we need the conditional
# to prevent an undefined constant error.
#
# This middleware adds a /_raindrops path that exposes stats. To see this in
# development, start the app like this instead of the usual running under thin:
#    bundle exec unicorn -l 3009
if defined?(Raindrops)
	use Raindrops::Middleware, :stats => $stats
end

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
    :extra_request_headers => { "GOVUK-Request-Id" => "govuk_request_id", "x-varnish" => "varnish_id" }
end

# Stop double slashes in URLs (even escaped ones) being flattened to single ones
set :protection, :except => [:path_traversal, :escaped_params, :frame_options]

enable :dump_errors, :raise_errors

run Rummager
