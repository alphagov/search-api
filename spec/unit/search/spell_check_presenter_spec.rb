require "spec_helper"

RSpec.describe Search::SpellCheckPresenter do
  context "#present" do
    it "parse the elasticsearch response and return suggestions" do
      es_response = {
        "suggest" => {
          "spelling_suggestions" => [{
            "text" => "some query",
            "options" => [{
              "text" => "the first suggestion",
              "score" => 0.17877324,
            }, {
              "text" => "the second suggestion",
              "score" => 0.14231323,
            }],
          }],
        },
      }

      presenter = described_class.new(es_response)

      expect(presenter.present).to eq(["the first suggestion", "the second suggestion"])
    end
  end
end
