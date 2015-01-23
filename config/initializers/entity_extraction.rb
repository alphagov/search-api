# This file may be overwritten on deployment to activate entity extraction in
# production. We default to disabled in production.

settings.search_config.enable_entity_extraction = (
  %w{development test}.include?(ENV['RACK_ENV'])
)
