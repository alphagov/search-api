require "govuk_app_config/govuk_unicorn"

GovukUnicorn.configure(self)

working_directory File.dirname(File.dirname(__FILE__))

# Preload the entire app. By preloading an application you can save some
# RAM resources as well as speed up server boot times.
preload_app true
