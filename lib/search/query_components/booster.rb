require "yaml"

module QueryComponents
  class Booster < BaseComponent
    FORMAT_BOOST_CONFIG = YAML.load_file('config/query/format_boosting.yml')
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
      format_boosts + [
        time_boost,
        closed_org_boost,
        devolved_org_boost,
        historic_edition_boost,
        guidance_boost,
        foi_boost,
      ]
    end

    def format_boosts
      FORMAT_BOOST_CONFIG["format_boosts"].map do |format, boost|
        {
          filter: { term: { format: format } },
          boost_factor: boost
        }
      end
    end

    def guidance_boost
      {
        filter: { term: { navigation_document_supertype: "guidance" } },
        boost_factor: 2.5
      }
    end

    def foi_boost
      {
        filter: { term: { content_store_document_type: "foi_release" } },
        boost_factor: 0.2
      }
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

    def closed_org_boost
      {
        filter: { term: { organisation_state: "closed" } },
        boost_factor: 0.2,
      }
    end

    def devolved_org_boost
      {
        filter: { term: { organisation_state: "devolved" } },
        boost_factor: 0.3,
      }
    end

    def historic_edition_boost
      {
        filter: { term: { is_historic: true } },
        boost_factor: 0.5,
      }
    end
  end
end
