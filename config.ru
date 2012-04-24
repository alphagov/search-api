app_path = File.dirname(__FILE__)
$:.unshift(app_path) unless $:.include?(app_path)

require "env"

require "bundler"
Bundler.require(:default, ENV['RACK_ENV'])

require "app"

enable :logging, :dump_errors, :raise_errors
in_development = ENV['RACK_ENV'] == 'development'
if in_development
  Dir.mkdir 'log' unless Dir.exists? 'log'
end

log = File.new("log/sinatra.log", "a")
if in_development
  log.sync = true
end
STDOUT.reopen(log)
STDERR.reopen(log)

run Sinatra::Application
