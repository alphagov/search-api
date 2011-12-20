require_relative "env"

configs = YAML.load(File.read(File.expand_path("../router.yml", __FILE__)))
set :router, configs[ENV["RACK_ENV"]]
