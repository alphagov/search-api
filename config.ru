app_path = File.dirname(__FILE__)
$:.unshift(app_path) unless $:.include?(app_path)

require 'app'
require "bundler"

Bundler.require(:default, ENV['RACK_ENV'])
run Sinatra::Application
