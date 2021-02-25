require "spec_helper"

RSpec.describe QueryComponents::Autocomplete do
  context "when enabled in debug options" do
    it "returns a set of autocomplete results" do
      builder = described_class.new(
        search_query_params(suggest: "autocomplete"),
      )

      result = builder.payload

      expect(result).to eq(
        "suggested_autocomplete" => {
          "prefix" => search_query_params.query,
          "completion" => {
            "field" => "autocomplete",
            "size" => 8,
            "skip_duplicates" => true,
          },
        },
      )
    end
  end
end
