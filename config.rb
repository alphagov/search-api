require_relative "env"

def set_config(kind)
  configs = YAML.load(File.read(File.expand_path("../#{kind}.yml", __FILE__)))
  set kind, configs[ENV["RACK_ENV"]]
end

set_config :router
set_config :solr
set_config :slimmer_headers

set :slimmer_asset_host, ENV["SLIMMER_ASSET_HOST"]
set :top_results, 4
set :max_more_results, 46
set :max_recommended_results, 2

set :recommended_format, "recommended-link"

configure :production, :development do
  use Slimmer::App, prefix: settings.router[:path_prefix], asset_host: settings.slimmer_asset_host
end
