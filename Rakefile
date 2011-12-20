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

    require_relative "router"

    require 'logger'
    @logger = Logger.new STDOUT
    @logger.level = Logger::DEBUG

    @router = Router::Client.new :logger => @logger
  end

  task :register_application => :router_environment do
    platform = ENV['FACTER_govuk_platform']
    app_id = settings.router[:app_id]
    url = "#{app_id}.#{platform}.alphagov.co.uk/"
    @logger.info "Registering #{app_id} application against #{url}..."
    @router.applications.update application_id: app_id, backend_url: url
  end

  task :register_routes => [ :router_environment ] do
    app_id = settings.router[:app_id]
    path_prefix = settings.router[:path_prefix]
    begin
      @logger.info "Registering full routes #{path_prefix}/search, #{path_prefix}/autocomplete"
      @router.routes.update application_id: app_id, route_type: :full,
        incoming_path: "#{path_prefix}/search"
      @router.routes.update application_id: app_id, route_type: :full,
        incoming_path: "#{path_prefix}/autocomplete"

      if path_prefix.empty?
        @logger.info "Registering prefix route #{path_prefix}/browse"
        @router.routes.update application_id: app_id, route_type: :prefix,
          incoming_path: "#{path_prefix}/browse"
      end
    rescue Router::Conflict => conflict_error
      @logger.error "Route already exists: #{conflict_error.existing}"
      raise conflict_error
    end
  end

  desc "Register search application and routes with the router (run this task on server in cluster)"
  task :register => [ :register_application, :register_routes ]
end

