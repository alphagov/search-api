require "rake/testtask"
require "rest-client"

File.join(File.dirname(__FILE__), "lib").tap do |path|
  $LOAD_PATH.unshift path unless $LOAD_PATH.include? path
end

require "elasticsearch_admin_wrapper"
require "reindexer"

desc "Run all the tests"
task "test" => ["test:units", "test:functionals", "test:integration"]

namespace "test" do
  desc "Run the unit tests"
  Rake::TestTask.new("units") do |t|
    t.libs << "test"
    t.test_files = FileList["test/unit/**/*_test.rb"]
    t.verbose = true
  end

  desc "Run the functional tests"
  Rake::TestTask.new("functionals") do |t|
    t.libs << "test"
    t.test_files = FileList["test/functional/**/*_test.rb"]
    t.verbose = true
  end

  desc "Run the integration tests"
  Rake::TestTask.new("integration") do |t|
    t.libs << "test"
    t.test_files = FileList["test/integration/**/*_test.rb"]
    t.verbose = true
  end
end

require "ci/reporter/rake/minitest" if ENV["RACK_ENV"] == "test"

class PushableLogger
  # Because RestClient uses the '<<' method, rather than the levelled Logger
  # methods, we have to put together a class that'll assign them a level

  def initialize(logger, level)
    @logger, @level = logger, level
  end

  def <<(message)
    @logger.add @level, message
  end
end

task :default => :test

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

    @admin_wrappers = {}
    @search_wrappers = {}

    elasticsearch_backends = settings.backends.select { |name, settings|
      settings["type"] == "elasticsearch"
    }

    real_backends = elasticsearch_backends.reject { |name, settings|
      # We're not interested in the primary index if it's just an alias
      name == :primary && elasticsearch_backends.values.count(settings) > 1
    }

    all_mappings = settings.elasticsearch_schema["mappings"]

    real_backends.each do |backend, backend_settings|
      @admin_wrappers[backend] = ElasticsearchAdminWrapper.new(
        backend_settings.symbolize_keys,
        settings.elasticsearch_schema,
        @logger
      )
      @search_wrappers[backend] = ElasticsearchWrapper.new(
        backend_settings.symbolize_keys,
        all_mappings[backend.to_s] || all_mappings["default"],
        @logger
      )
    end

    @admin_wrapper = ElasticsearchAdminWrapper.new(
      backend_settings,
      settings.elasticsearch_schema,
      @logger
    )
    @search_wrapper = ElasticsearchWrapper.new(
      backend_settings,
      all_mappings[backend_name] || all_mappings["default"],
      @logger
    )

    RestClient.log = PushableLogger.new(@logger, Logger::DEBUG)
  end

  desc "Create or update the elasticsearch mappings"
  task :put_mapping => [:rummager_environment, :ensure_index] do
    @admin_wrapper.put_mappings
  end

  desc "Ensure the elasticsearch index exists"
  task :ensure_index => :rummager_environment do
    @admin_wrapper.ensure_index
  end

  # Alias for the old task name
  task :create_index => :ensure_index do end

  desc "Delete the elasticsearch index"
  task :delete_index => :rummager_environment do
    @admin_wrapper.delete_index
  end

  task :which_indexes_exist => :rummager_environment do
    @admin_wrappers.each do |wrapper_name, wrapper|
      if wrapper.index_exists?
        puts "'#{wrapper_name}' index exists"
      else
        puts "'#{wrapper_name}' index does not exist"
      end
    end
  end

  desc "Ensure that all elasticsearch indexes exist"
  task :ensure_all_indexes => :rummager_environment do
    @admin_wrappers.each do |wrapper_name, wrapper|
      puts "Updating/inserting index '#{wrapper_name}'..."
      wrapper.ensure_index
    end
  end

  # Alias for the old task name
  task :create_all_indexes => :ensure_all_indexes do end

  task :delete_all_indexes => :rummager_environment do
    @admin_wrappers.each_value &:delete_index
  end

  desc "Create or update all elasticsearch mappings"
  task :put_all_mappings => [:rummager_environment, :ensure_all_indexes] do
    @admin_wrappers.each do |wrapper_name, wrapper|
      puts "Putting mappings for index '#{wrapper_name}'..."
      wrapper.put_mappings
    end
  end

  desc "List the content formats in the index"
  task :list_formats => [:rummager_environment] do
    @search_wrapper.formats.each do |facet|
      puts "#{facet["term"]}: #{facet["count"]} documents"
    end
  end

  desc "Delete all documents with a given format"
  task :delete_by_format, [:format] => [:rummager_environment] do |t, args|
    unless args[:format]
      raise "No format supplied: aborting"
    end

    puts "Deleting all items with the #{args[:format]} format..."
    @search_wrapper.delete_by_format args[:format]
    puts "...done!"
    puts "You probably want to run the rummager:list_formats task now, to make"
    puts "sure this worked as you expected."
  end

  desc "Reindex all content in the index"
  task :reindex => :rummager_environment do
    Reindexer.new(@search_wrapper, @logger).reindex_all
  end

  desc "Reindex all content in all indexes"
  task :reindex_all => :rummager_environment do
    @search_wrappers.each do |name, wrapper|
      puts "Reindexing '#{name}' index..."
      Reindexer.new(wrapper, @logger).reindex_all
      puts "...done!"
    end
  end

end
