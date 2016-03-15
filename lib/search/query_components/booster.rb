module QueryComponents
  class Booster < BaseComponent
    def wrap(core_query)
      {
        function_score: {
          boost_mode: :multiply,
          query: {
            bool: {
              should: [core_query]
            }
          },
          functions: boost_filters,
          score_mode: "multiply",
        }
      }
    end

  private

    def boost_filters
      boost_factor_filters + [time_boost]
    end

    def boost_factor_filters
      [
        # By manual
        boost_factor_filter(:manual, 'service-manual',          0.3),

        # By mainstream formats
        boost_factor_filter(:format, "smart-answer",            1.5),
        boost_factor_filter(:format, "transaction",             1.5),
        boost_factor_filter(:format, "topical_event",           1.5),
        boost_factor_filter(:format, "minister",                1.7),
        boost_factor_filter(:format, "organisation",            2.5),
        boost_factor_filter(:format, "topic",                   1.5),
        boost_factor_filter(:format, "document_series",         1.3),
        boost_factor_filter(:format, "document_collection",     1.3),
        boost_factor_filter(:format, "operational_field",       1.5),
        boost_factor_filter(:format, "contact",                 0.3),

        # Hide mainstream browse pages for now.
        boost_factor_filter(:format, "mainstream_browse_page",  0),

        # By organisation state
        boost_factor_filter(:organisation_state, "closed",      0.2),
        boost_factor_filter(:organisation_state, "devolved",    0.3),

        # By historic edition
        boost_factor_filter(:is_historic, true,                 0.5),
      ]
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

    def boost_factor_filter(attribute, value, boost_factor)
      {
        filter: { term: { attribute => value } },
        boost_factor: boost_factor,
      }
    end
  end
end
