ENV["RACK_ENV"] ||= "development"

configure :production, :development do
  use Slimmer::App
end


set :solr, lambda {
  config = YAML.load(File.read(File.expand_path("../solr.yml", __FILE__)))
  SolrWrapper.new(DelSolr::Client.new(config[ENV["RACK_ENV"]]))
}.call

set :top_results, 4
set :max_more_results, 46
