require "sinatra"
require "slimmer"

use Slimmer::App, :template_path => "./public/templates"

get "/search" do
  erb :search
end
