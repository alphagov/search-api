require "govuk_app_config/govuk_unicorn"

GovukUnicorn.configure(self)

working_directory File.dirname(File.dirname(__FILE__))

# Preload the entire app. By preloading an application you can save some
# RAM resources as well as speed up server boot times.
preload_app true

before_fork do |_server, _worker|
  # Throttles the master from starting new workers too quickly.
  # Creates a more gradual roll out of workers so that users are
  # less likely to have their request handled by a worker that has
  # just booted, and may respond to requests slower.
  sleep 5 unless ENV["RACK_ENV"] == "development"
end
