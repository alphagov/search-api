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

    http = Router::HttpClient.new "http://cache.cluster:8080/router", @logger

    @router = Router::Client.new http
  end

  task :register_application => :router_environment do
    platform = ENV['FACTER_govuk_platform']
    url = "search.#{platform}.alphagov.co.uk/"
    begin
      @logger.info "Registering application..."
      @router.applications.create application_id: "search", backend_url: url
    rescue Router::Conflict
      application = @router.applications.find "search"
      puts "Application already registered: #{application.inspect}"
    end
  end

  task :register_routes => [ :router_environment, :environment ] do
    begin
      @logger.info "Registering prefix /search"
      @router.routes.create application_id: "search", route_type: :prefix,
        incoming_path: "/search"
    rescue => e
      puts [ e.message, e.backtrace ].join("\n")
    end
  end

  desc "Register search application and routes with the router (run this task on server in cluster)"
  task :register => [ :register_application, :register_routes ]
end

