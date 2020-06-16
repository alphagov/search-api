class PropertyBoostCalculator
  def initialize
    config = YAML.load_file("config/query/boosting.yml")
    external_search_overrides = config.fetch("external_search", {})
    @boost_config = config["base"].merge(external_search_overrides)
  end

  def boost(document)
    raw_boosts = @boost_config.map do |property, boosts|
      if document[property] && boosts[document[property]]
        boosts[document[property]]
      else
        1
      end
    end

    overall_boost = raw_boosts.inject(:*)

    withdrawn_status_boost(document) *
      part_boost(document) *
      map_boost_to_priority(overall_boost).round(2)
  end

private

  # Convert a boost (which may be any positive or zero value) to a sitemap
  # priority.
  #
  # The conversion must produce a number between zero and one to match the
  # sitemap format (https://www.sitemaps.org/protocol.html), and boost ordering
  # must be preserved (i.e. if one page has a higher combined boost than
  # another one, its priority must also be higher).
  #
  # https://www.wolframalpha.com/input/?i=plot+1+-+2%5E(-x),+x+%3D+0+to+5
  def map_boost_to_priority(boost)
    (1 - 2**-boost).to_f
  end

  def withdrawn_status_boost(document)
    document["is_withdrawn"] ? 0.25 : 1
  end

  def part_boost(document)
    document["is_part"] ? 0.75 : 1
  end
end
