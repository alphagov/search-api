require "rake/testtask"

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
  t.verbose = true
end

require "ci/reporter/rake/test_unit" if ENV["RACK_ENV"] == "test"

task :default => :test

namespace :router do
  task :router_environment do
    Bundler.require :router, :default

    require 'logger'
    @logger = Logger.new STDOUT
    @logger.level = Logger::DEBUG

    @router = Router::Client.new :logger => @logger
  end

  task :register_application => :router_environment do
    platform = ENV['FACTER_govuk_platform']
    url = "search.#{platform}.alphagov.co.uk/"
    @logger.info "Registering application..."
    @router.applications.update application_id: "search", backend_url: url
  end

  task :register_routes => [ :router_environment ] do
    @logger.info "Registering prefix /search"
    @router.routes.update application_id: "search", route_type: :prefix,
      incoming_path: "/search"
  end

  desc "Register search application and routes with the router (run this task on server in cluster)"
  task :register => [ :register_application, :register_routes ]
end

