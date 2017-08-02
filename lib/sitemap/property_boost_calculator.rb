class PropertyBoostCalculator
  def initialize
    @boost_config = YAML.load_file('config/query/boosting.yml')
    @max_boosts = calculate_max_boosts
  end

  def boost(document)
    boost_values = @boost_config.map do |property, boosts|
      if document.has_field?(property) && boosts[document.get(property)]
        page_boost = boosts[document.get(property)]
      else
        page_boost = 1
      end

      # Normalise format boost to always give a value between 0 and 1
      page_boost.to_f / @max_boosts[property]
    end

    boost_values.inject(:*).round(2)
  end

private

  def calculate_max_boosts
    @boost_config.keys.each_with_object({}) do |property, max_boosts|
      boosts = @boost_config[property]

      max_configured_boost = boosts.values.max
      max_boost = max_configured_boost >= 1 ? max_configured_boost : 1

      max_boosts[property] = max_boost
    end
  end
end
