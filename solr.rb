require_relative "env"

configs = YAML.load(File.read(File.expand_path("../solr.yml", __FILE__)))
set :solr, configs[ENV["RACK_ENV"]]
