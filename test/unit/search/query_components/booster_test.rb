require "test_helper"
require "search/query_builder"

class BoosterTest < ShouldaUnitTestCase
  should "add a function score to the query" do
    Timecop.freeze("2016-03-11 16:00".to_time) do
      builder = QueryComponents::Booster.new(search_query_params)
      result = builder.wrap({ some: 'query' })

      expected = {
        function_score: {
          boost_mode: :multiply,
          score_mode: "multiply",
          query: {
            bool: {
              should: [
                { some: "query" }
              ]
            }
          },
          functions: [
            { filter: { term: { format: "service_manual_guide" } },   boost_factor: 0.3 },
            { filter: { term: { format: "service_manual_topic" } },   boost_factor: 0.3 },
            { filter: { term: { format: "smart-answer" } },           boost_factor: 1.5 },
            { filter: { term: { format: "transaction" } },            boost_factor: 1.5 },
            { filter: { term: { format: "topical_event" } },          boost_factor: 1.5 },
            { filter: { term: { format: "minister" } },               boost_factor: 1.7 },
            { filter: { term: { format: "organisation" } },           boost_factor: 2.5 },
            { filter: { term: { format: "topic" } },                  boost_factor: 1.5 },
            { filter: { term: { format: "document_series" } },        boost_factor: 1.3 },
            { filter: { term: { format: "document_collection" } },    boost_factor: 1.3 },
            { filter: { term: { format: "operational_field" } },      boost_factor: 1.5 },
            { filter: { term: { format: "contact" } },                boost_factor: 0.3 },
            { filter: { term: { format: "aaib_report" } },            boost_factor: 0.2 },
            { filter: { term: { format: "dfid_research_output" } },   boost_factor: 0.2 },
            { filter: { term: { format: "hmrc_manual_section" } },    boost_factor: 0.2 },
            { filter: { term: { format: "mainstream_browse_page" } }, boost_factor: 0 },
            { filter: { term: { search_format_types: "announcement" } },
              script_score: {
                script: "((0.05 / ((3.16*pow(10,-11)) * abs(now - doc['public_timestamp'].date.getMillis()) + 0.05)) + 0.12)",
                params: { now: 1457712000000 }
              }
            },
            { filter: { term: { organisation_state: "closed" } }, boost_factor: 0.2 },
            { filter: { term: { organisation_state: "devolved" } }, boost_factor: 0.3 },
            { filter: { term: { is_historic: true } }, boost_factor: 0.5 }
          ]
        }
      }

      assert_equal expected, result
    end
  end
end
