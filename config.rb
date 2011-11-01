configure :production do
  use Slimmer::App, :asset_host => "http://static.production.alphagov.co.uk"
end

configure :development do
  use Slimmer::App, :template_path => "./public/templates"
end

set :top_results, 4
set :max_more_results, 6
