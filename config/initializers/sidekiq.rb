require "govuk_sidekiq/sidekiq_initializer"

GovukSidekiq::SidekiqInitializer.setup_sidekiq(
  ENV.fetch("GOVUK_APP_NAME", "search-api"),
  {},
)
