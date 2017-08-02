require "yaml"

module QueryComponents
  class Booster < BaseComponent
    BOOST_CONFIG = YAML.load_file('config/query/boosting.yml')
    DEFAULT_BOOST = 1

    def wrap(core_query)
      {
        function_score: {
          boost_mode: :multiply,
          score_mode: :multiply,
          query: {
            bool: {
              should: [core_query]
            }
          },
          functions: boost_filters,
        }
      }
    end

  private

    def boost_filters
      property_boosts + [time_boost]
    end

    def property_boosts
      BOOST_CONFIG.flat_map do |property, boosts|
        boosts.map do |value, boost|
          {
            filter: { term: { property.to_sym => value } },
            boost_factor: boost
          }
        end
      end
    end

    # An implementation of http://wiki.apache.org/solr/FunctionQuery#recip
    # Curve for 2 months: http://www.wolframalpha.com/share/clip?f=d41d8cd98f00b204e9800998ecf8427e5qr62u0si
    #
    # Behaves as a freshness boost for newer documents with a public_timestamp and search_format_types announcement
    def time_boost
      {
        filter: { term: { search_format_types: "announcement" } },
        script_score: {
          script: "((0.05 / ((3.16*pow(10,-11)) * abs(now - doc['public_timestamp'].date.getMillis()) + 0.05)) + 0.12)",
          params: {
            now: time_in_millis_to_nearest_minute,
          },
        }
      }
    end

    def time_in_millis_to_nearest_minute
      (Time.now.to_i / 60) * 60000
    end
  end
end
