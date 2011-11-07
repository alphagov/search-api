ENV["RACK_ENV"] ||= "development"

configure :production do
  use Slimmer::App, :asset_host => "http://static.production.alphagov.co.uk"
end

configure :development do
  use Slimmer::App, :template_path => "./public/templates"
end

set :solr, lambda {
  config = YAML.load(File.read(File.expand_path("../solr.yml", __FILE__)))
  SolrWrapper.new(DelSolr::Client.new(config[ENV["RACK_ENV"]]))
}.call

set :top_results, 4
set :max_more_results, 46
