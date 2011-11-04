app_path = File.dirname(__FILE__)
$:.unshift(app_path) unless $:.include?(app_path)

require 'app'
require "bundler"

set :raise_errors, true
log = File.new("sinatra.log", "a")
STDOUT.reopen(log)
STDERR.reopen(log)

Bundler.require(:default, ENV['RACK_ENV'])
run Sinatra::Application
