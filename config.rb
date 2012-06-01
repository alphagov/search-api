require_relative "env"

def config_for(kind)
  YAML.load_file(File.expand_path("../#{kind}.yml", __FILE__))
end

set :router, config_for(:router)
set :solr, config_for(:solr)[ENV["RACK_ENV"]]
set :slimmer_headers, config_for(:slimmer_headers)

set :slimmer_asset_host, ENV["SLIMMER_ASSET_HOST"]
set :top_results, 4
set :max_more_results, 46
set :max_recommended_results, 2

set :recommended_format, "recommended-link"

set :boost_csv, "data/boosted_links.csv"

set :format_order, ['transaction', 'answer', 'programme', 'guide']

set :format_name_alternatives, {
  "programme" => "Benefits and schemes",
  "transaction" => "Services",
  "answer" => "Quick answers",
}

configure :development do
  set :protection, false
  use Slimmer::App, prefix: settings.router[:path_prefix], asset_host: settings.slimmer_asset_host
end

configure :production do
  use Slimmer::App, prefix: settings.router[:path_prefix], asset_host: settings.slimmer_asset_host, cache_templates: true
end


