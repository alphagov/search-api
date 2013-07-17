require_relative "env"
require "search_config"
require_relative "exception_mailer"
require "config/logging"

set :search_config, SearchConfig.new
set :default_index_name, "mainstream"

set :static, true
set :static_cache_control, [:public, :max_age => 86400]
set :public_folder, File.join(File.dirname(__FILE__), 'public', 'system')

configure :development do
  set :protection, false
end

# Enable custom error handling (eg ``error Exception do;...end``)
# Disable fancy exception pages (but still get good ones).
disable :show_exceptions

initializers_path = File.expand_path("config/initializers/*.rb", File.dirname(__FILE__))

Dir[initializers_path].each { |f| require f }
