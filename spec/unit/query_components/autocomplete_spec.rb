require "spec_helper"

RSpec.describe QueryComponents::Autocomplete do
  context "when enabled in debug options" do
    it "returns a set of autocomplete results" do
      AUTOCOMPLETE_FIELD = "title.edgengram".freeze

      builder = described_class.new(
        search_query_params(suggest: "autocomplete"),
      )

      result = builder.payload

      expect(result).to eq(
        "bool" => {
          "must" => {
            "match" => {
              AUTOCOMPLETE_FIELD => {
                "query" => search_query_params.query,
                "operator" => "and",
              },
            },
          },
          "must_not" => {
          # The below are excluded from any autocomplete suggestions
            "terms" => {
              "format" => [
                #As referenced from config/govuk_index/mapped_document_types.yaml
                "hmrc_manual_section",
                "dfid_research_output",
                "employment_tribunal_decision",
                "employment_appeal_tribunal_decision",
                ],
              },
            },
          },
        )
    end
  end
end
