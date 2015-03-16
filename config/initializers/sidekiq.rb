require "sidekiq"

redis_config_hash = YAML.load_file("config/redis.yml").symbolize_keys

if ENV["RACK_ENV"] == "test"
  namespace = "#{redis_config_hash[:namespace]}-#{ENV['RACK_ENV']}"
else
  namespace = redis_config_hash[:namespace]
end

redis_config = {
  url: "redis://#{redis_config_hash[:host]}:#{redis_config_hash[:port]}/0",
  namespace: namespace
}

Sidekiq.configure_server do |config|
  config.redis = redis_config
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end
