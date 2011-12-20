require_relative "env"

configs = YAML.load(File.read(File.expand_path("../solr.yml", __FILE__)))
client = DelSolr::Client.new(configs[ENV["RACK_ENV"]])
set :solr, SolrWrapper.new(client)

