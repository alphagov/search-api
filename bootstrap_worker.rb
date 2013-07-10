# Slightly hacky script to bootstrap the Sidekiq worker

project_root = File.dirname(__FILE__)
library_path = File.join(project_root, "lib")

[project_root, library_path].each do |path|
  $LOAD_PATH.unshift(path) unless $LOAD_PATH.include?(path)
end

require "config/initializers/sidekiq"
require "elasticsearch/bulk_index_worker"
