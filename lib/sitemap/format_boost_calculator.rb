class FormatBoostCalculator
  def initialize
    format_boost_config = YAML.load_file('config/query/format_boosting.yml')
    @format_boosts = format_boost_config["format_boosts"]
  end

  def boost(format)
    page_boost = @format_boosts[format] || 1

    # Normalise format boost to always give a value between 0 and 1
    page_boost.to_f / max_boost
  end

private

  def max_boost
    @_max_boost ||= @format_boosts.values.max
  end
end
