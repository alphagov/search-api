app_path = File.dirname(__FILE__)
$:.unshift(app_path) unless $:.include?(app_path)

require "env"

require "bundler"
Bundler.require(:default, ENV['RACK_ENV'])

require "app"

enable :logging, :dump_errors, :raise_errors

log = File.new("sinatra.log", "a")
if ENV['RACK_ENV'] == "development"
  log.sync = true
end
STDOUT.reopen(log)
STDERR.reopen(log)

run Sinatra::Application
