class RummagerConfig
  def config_for(kind)
    YAML.load_file(File.expand_path("../#{kind}.yml", __FILE__))
  end

  def backend_config
    # Note that we're not recursively symbolising keys, because the config for
    # each backend is currently flat. We may need to revisit this.
    config_for(:backends)[ENV["RACK_ENV"]].symbolize_keys
  end

  def elasticsearch_schema
    config_for("elasticsearch_schema")
  end
end