PROJECT_ROOT = File.dirname(__FILE__)
LIBRARY_PATH = File.join(PROJECT_ROOT, "lib")

[PROJECT_ROOT, LIBRARY_PATH].each do |path|
  $LOAD_PATH.unshift(path) unless $LOAD_PATH.include?(path)
end

require "rummager"
require "rummager/config"

Dir[File.join(PROJECT_ROOT, "lib/tasks/**/*.rake")].each { |file| load file }

# rubocop:disable Lint/SuppressedException
begin
  require "pact/tasks"
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
end
# rubocop:enable Lint/SuppressedException

task default: %i[lint spec pact:verify]
