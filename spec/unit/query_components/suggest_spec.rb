require "spec_helper"

RSpec.describe QueryComponents::Suggest do
  context "with b variant of suggestions" do
    it "makes the suggestion algorithm levenshtein" do
      SPELLING_FIELD = "spelling_text".freeze

      builder = described_class.new(
        search_query_params(suggest: "spelling_with_highlighting", ab_tests: { spelling_suggestions: "B" }),
      )

      result = builder.payload

      expect(result).to eq(
        text: search_query_params.query,
        spelling_suggestions: {
          phrase: {
            field: SPELLING_FIELD,
            size: 1,
            max_errors: 3,
            direct_generator: [{
              field: SPELLING_FIELD,
              suggest_mode: "missing",
              string_distance: "levenshtein",
              sort: "score",
            }],
          }.merge(highlight: {
            pre_tag: "<mark>",
            post_tag: "</mark>",
          }),
        },
      )
    end
  end
end
