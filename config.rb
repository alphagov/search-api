require_relative "routes"
require_relative "solr"

configure :production, :development do
  use Slimmer::App
end

set :top_results, 4
set :max_more_results, 46
set :max_recommended_results, 2

set :recommended_format, "recommended-link"
