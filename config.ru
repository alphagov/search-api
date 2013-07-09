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
in_preview = ENV['FACTER_govuk_platform'] == 'preview'

if in_development or in_preview
  set :logging, $DEBUG ? Logger::DEBUG : Logger::INFO
else
  enable :logging
end

# Stop double slashes in URLs (even escaped ones) being flattened to single ones
set :protection, :except => [:path_traversal, :escaped_params, :frame_options]

enable :dump_errors, :raise_errors

unless in_development
  log = File.new("log/production.log", "a")
  STDOUT.reopen(log)
  STDERR.reopen(log)
end

run Rummager
