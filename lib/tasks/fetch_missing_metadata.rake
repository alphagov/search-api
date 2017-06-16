require 'missing_metadata/runner'

desc "Fetch missing document metadata from the publishing api"
task :populate_metadata do
  MissingMetadata::Runner.new(ENV.fetch('MISSING_FIELD')).update
end
