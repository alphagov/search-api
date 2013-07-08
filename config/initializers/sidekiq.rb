# This file will be overwritten on deployment
require "sidekiq"

redis_config = {
  :url => "redis://localhost:6379/0",
  :namespace => "rummager"
}

Sidekiq.configure_server do |config|
  config.redis = redis_config
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end
