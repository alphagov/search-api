require "spec_helper"

RSpec.describe Search::AutocompletePresenter do
  describe "#present" do
    subject(:presenter) { described_class.new(es_response) }

    context "when there aren't any suggestions" do
      let(:es_response) { example_es_response_without_autocomplete }

      it "returns an empty list" do
        expect(presenter.present).to eq([])
      end
    end

  end

  def example_es_response_without_autocomplete
    {
      "took" => 166,
      "timed_out" => false,
      "_shards" => {
        "total" => 9, "successful" => 9, "skipped" => 0, "failed" => 0
      },
      "hits" => {
        "total" => 0, "max_score" => nil, "hits" => []
      },
      "autocomplete" => {
        "suggested_autocomplete" => [{
          "text" => "taxz",
          "offset" => 0,
          "length" => 4,
          "options" => [],
        }],
      },
    }
  end
end
