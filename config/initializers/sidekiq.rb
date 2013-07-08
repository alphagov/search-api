# This file will be overwritten on deployment
require "sidekiq"

if ENV["RACK_ENV"]
  namespace = "rummager-#{ENV['RACK_ENV']}"
else
  namespace = "rummager"
end

redis_config = {
  :url => "redis://localhost:6379/0",
  :namespace => namespace
}

Sidekiq.configure_server do |config|
  config.redis = redis_config
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end
