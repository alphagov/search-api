require "govuk_sidekiq/sidekiq_initializer"

if ENV["RACK_ENV"] == "test"
  redis_config = {
    url: "redis://127.0.0.1:6379/0",
    namespace: "search-api-test"
  }

  Sidekiq.configure_server do |config|
    config.redis = redis_config
  end

  Sidekiq.configure_client do |config|
    config.redis = redis_config
  end
else
  redis_config = {
    host: ENV.fetch("REDIS_HOST", "127.0.0.1"),
    port: ENV.fetch("REDIS_PORT", 6379)
  }

  GovukSidekiq::SidekiqInitializer.setup_sidekiq('search-api', redis_config)
end
