require "spec_helper"

RSpec.describe Search::AutocompletePresenter do
  describe "#present" do
    subject(:presenter) { described_class.new(es_response) }

    context "when there aren't any suggestions" do
      let(:es_response) { {} }

      it "returns an empty list" do
        expect(presenter.present).to eq([])
      end
    end

    context "when there is one suggestion" do
      let(:es_response) do
        {
          "autocomplete" => [
            [
              "ignored_metadata",
              [
                {
                  "options" => [
                    {
                      "_source" => {
                        "autocomplete" => {
                          "input" => "Apple",
                        },
                      },
                    },
                  ],
                },
              ],
            ],
          ],
        }
      end

      it "returns the suggestion" do
        expect(presenter.present).to eq(%w[Apple])
      end
    end

    context "where there are multiple suggestions" do
      let(:es_response) do
        {
          "autocomplete" => [
            [
              "ignored_metadata",
              [
                {
                  "options" => [
                    {
                      "_source" => {
                        "autocomplete" => {
                          "input" => "Apple",
                        },
                      },
                    },
                    {
                      "_source" => {
                        "autocomplete" => {
                          "input" => "Apricot",
                        },
                      },
                    },
                  ],
                },
                {
                  "options" => [
                    {
                      "_source" => {
                        "autocomplete" => {
                          "input" => "Banana",
                        },
                      },
                    },
                  ],
                },
              ],
            ],
          ],
        }
      end

      it "returns the suggestions" do
        expect(presenter.present).to eq(%w[Apple Apricot Banana])
      end
    end
  end
end
