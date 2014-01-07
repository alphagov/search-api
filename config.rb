require "sinatra"
require_relative "env"
require "search_config"
require_relative "exception_mailer"
require "ses_mailer"  # For the exception_notification initialiser
require "config/logging"

set :search_config, SearchConfig.new
set :default_index_name, "mainstream"

configure :development do
  set :protection, false
end

# Enable custom error handling (eg ``error Exception do;...end``)
# Disable fancy exception pages (but still get good ones).
disable :show_exceptions

initializers_path = File.expand_path("config/initializers/*.rb", File.dirname(__FILE__))

Dir[initializers_path].each { |f| require f }
