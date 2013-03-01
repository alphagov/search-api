require_relative "env"
require "active_support/core_ext/hash/keys"
require_relative "exception_mailer"

def config_for(kind)
  YAML.load_file(File.expand_path("../#{kind}.yml", __FILE__))
end

def backend_config
  # Note that we're not recursively symbolising keys, because the config for
  # each backend is currently flat. We may need to revisit this.
  config_for(:backends)[ENV["RACK_ENV"]].symbolize_keys
end

set :backends, backend_config
set :elasticsearch, config_for("elasticsearch")
set :elasticsearch_schema, config_for("elasticsearch_schema")

set :recommended_format, "recommended-link"
set :inside_government_link, "inside-government-link"

configure :development do
  set :protection, false
end

initializers_path = File.expand_path("config/initializers/*.rb", File.dirname(__FILE__))

Dir[initializers_path].each { |f| require f }
