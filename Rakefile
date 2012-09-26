require "rake/testtask"
require "rest-client"

File.join(File.dirname(__FILE__), "lib").tap do |path|
  $LOAD_PATH.unshift path unless $LOAD_PATH.include? path
end

require "elasticsearch_admin_wrapper"

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

    require_relative "config"

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
      @logger.info "Registering full route #{path_prefix}/autocomplete"
      @router.routes.update application_id: app_id, route_type: :full,
        incoming_path: "#{path_prefix}/autocomplete"
      @logger.info "Registering full route #{path_prefix}/preload-autocomplete"
      @router.routes.update application_id: app_id, route_type: :full,
        incoming_path: "#{path_prefix}/preload-autocomplete"
      @logger.info "Registering full route #{path_prefix}/sitemap.xml"
      @router.routes.update application_id: app_id, route_type: :full,
        incoming_path: "#{path_prefix}/sitemap.xml"

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
  task :register => :router_environment do
    case settings.router[:app_id]
    when 'search'
      Rake::Task["router:register_application"].invoke
      Rake::Task["router:register_routes"].invoke
    when 'whitehall-search'
      # Whitehall search is proxied via the whitehall application
      # and is never accessed directly by the public, so it doesn't
      # need to be routed
      puts "Not registering whitehall-search with router"
    else
      raise "Unexpected app_id '#{settings.router[:app_id]}' in router.yml"
    end
  end
end

namespace :rummager do

  # Set up the necessary backend and logging configuration for elasticsearch-
  # related tasks. This task isn't any use on its own, but is a prerequisite
  # for other tasks in this namespace.
  task :rummager_environment do
    Bundler.require :default
    require_relative "config"
    require_relative "backends"

    require "logger"
    @logger = Logger.new STDOUT
    @logger.level = verbose ? Logger::DEBUG : Logger::INFO

    backend_name = ENV['BACKEND'] || 'primary'
    backend_settings = settings.backends[backend_name.to_sym]

    unless backend_settings
      raise RuntimeError, "You must provide a valid backend name, i.e. BACKEND=mainstream rake rummager:put_mapping"
    end

    backend_settings = backend_settings.symbolize_keys

    unless backend_settings[:type] == "elasticsearch"
      raise RuntimeError, "This task only works with elasticsearch backends"
    end

    @wrappers = {}

    settings.backends.reject { |k, v| v['type'] == 'none' }.each do |key, value|
      @wrappers[key] = ElasticsearchAdminWrapper.new(
        value.symbolize_keys,
        settings.elasticsearch_schema,
        @logger
      )
    end

    @wrapper = ElasticsearchAdminWrapper.new(
      backend_settings,
      settings.elasticsearch_schema,
      @logger
    )
    RestClient.log = @logger
  end

  desc "Create or update the elasticsearch mappings"
  task :put_mapping => [:rummager_environment, :create_index] do
    @wrapper.put_mappings
  end

  desc "Ensure the elasticsearch index exists"
  task :create_index => :rummager_environment do
    @wrapper.create_index
  end

  desc "Ensure that all elasticsearch indexes exist"
  task :create_all_indexes => :rummager_environment do
    @wrappers.each_value.each do |wrapper|
      wrapper.create_index
    end
  end

  desc "Create or update all elasticsearch mappings"
  task :put_all_mappings => [:rummager_environment, :create_all_indexes] do
    @wrappers.each_value.each do |wrapper|
      wrapper.put_mappings
    end
  end
end
