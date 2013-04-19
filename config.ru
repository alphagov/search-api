app_path = File.dirname(__FILE__)
$:.unshift(app_path) unless $:.include?(app_path)

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
