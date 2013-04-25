require_relative "env"
require "active_support/core_ext/hash/keys"
require "search_config"
require_relative "exception_mailer"

set :search_config, SearchConfig.new
set :default_index_name, "mainstream"

set :static, true
set :public_folder, File.join(File.dirname(__FILE__), 'public', 'system')

configure :development do
  set :protection, false
end

initializers_path = File.expand_path("config/initializers/*.rb", File.dirname(__FILE__))

Dir[initializers_path].each { |f| require f }
