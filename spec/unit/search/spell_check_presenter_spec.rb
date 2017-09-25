require 'spec_helper'

RSpec.describe 'Search::SpellCheckPresenterTest', tags: ['shoulda'] do
  context "#present" do
    it "parse the elasticsearch response and return suggestions" do
      es_response = {
        "suggest" => {
          "spelling_suggestions" => [{
            "text" => "some query",
            "options" => [{
              "text" => "the first suggestion",
              "score" => 0.17877324
            }, {
              "text" => "the second suggestion",
              "score" => 0.14231323
            }]
          }]
        }
      }

      presenter = Search::SpellCheckPresenter.new(es_response)

      assert_equal presenter.present, ["the first suggestion", "the second suggestion"]
    end
  end
end
