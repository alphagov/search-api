class ElasticsearchConfig
  def config
    config_for("elasticsearch")[ENV["RACK_ENV"]]
  end

  def config_path
    File.expand_path("../config/schema", File.dirname(__FILE__))
  end

private

  def config_path_for(kind)
    File.expand_path("../#{kind}.yml", File.dirname(__FILE__))
  end

  def config_for(kind)
    # https://ruby-doc.org/stdlib-3.1.0/libdoc/psych/rdoc/Psych.html#method-c-safe_load
    YAML.safe_load(
      ERB.new(
        File.read(config_path_for(kind)),
      ).result, aliases: true, permitted_classes: [Date]
    )
  end
end
