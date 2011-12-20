require_relative "env"

configs = YAML.load(File.read(File.expand_path("../routes.yml", __FILE__)))
set :routes, configs[ENV["RACK_ENV"]]
