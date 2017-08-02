class FormatBoostCalculator
  def initialize
    boost_config = YAML.load_file('config/query/boosting.yml')
    @format_boosts = boost_config["format"]
  end

  def boost(format)
    page_boost = @format_boosts[format] || 1

    # Normalise format boost to always give a value between 0 and 1
    (page_boost.to_f / max_boost).round(2)
  end

private

  def max_boost
    @_max_boost ||= @format_boosts.values.max
  end
end
