require_relative "router"
require_relative "solr"

configure :production, :development do
  use Slimmer::App, prefix: settings.router[:path_prefix]
end

set :top_results, 4
set :max_more_results, 46
set :max_recommended_results, 2

set :recommended_format, "recommended-link"
