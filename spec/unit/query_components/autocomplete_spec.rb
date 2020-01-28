require "spec_helper"

RSpec.describe QueryComponents::Autocomplete do
  context "when enabled in debug options" do
    it "returns a set of autocomplete results" do
      AUTOCOMPLETE_FIELD = "autocomplete".freeze

      builder = described_class.new(
        search_query_params(suggest: "autocomplete"),
      )

      result = builder.payload

      expect(result).to eq(
        "suggested_autocomplete" => {
          "prefix" => search_query_params.query,
          "completion" => {
            "field" => AUTOCOMPLETE_FIELD,
            "size" => 8,
            "skip_duplicates" => true,
            "fuzzy" => {
              "fuzziness" => "AUTO",
            },
          },
        },
        )
    end
  end
end
