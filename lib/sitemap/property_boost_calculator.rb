class PropertyBoostCalculator
  def initialize
    boost_config = YAML.load_file('config/query/boosting.yml')
    @format_boosts = boost_config["format"]
  end

  def boost(document)
    page_boost = @format_boosts[document.format] || 1

    # Normalise format boost to always give a value between 0 and 1
    (page_boost.to_f / max_boost).round(2)
  end

private

  def max_boost
    @_max_boost ||= calculate_max_boost
  end

  def calculate_max_boost
    max_configured_boost = @format_boosts.values.max
    max_configured_boost >= 1 ? max_configured_boost : 1
  end
end
