require_relative "env"
require "active_support/core_ext/hash/keys"
require_relative "exception_mailer"

def config_for(kind)
  YAML.load_file(File.expand_path("../#{kind}.yml", __FILE__))
end

set :elasticsearch, config_for("elasticsearch")
set :elasticsearch_schema, config_for("elasticsearch_schema")

set :recommended_format, "recommended-link"
set :inside_government_link, "inside-government-link"

configure :development do
  set :protection, false
end

initializers_path = File.expand_path("config/initializers/*.rb", File.dirname(__FILE__))

Dir[initializers_path].each { |f| require f }
