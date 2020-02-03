require "govuk_app_config/govuk_unicorn"

GovukUnicorn.configure(self)

working_directory File.dirname(File.dirname(__FILE__))
