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

    context "where there are autocomplete suggestions" do
      let(:es_response) { example_es_response_with_autocomplete }

      it "returns the suggestions" do
        expected_responses = [
          "Taxpayers given more time for voluntary National Insurance contributions",
          "Tax-free allowances on property and trading income",
          "Tax treaties",
          "Tax relief for residential landlords: how it's worked out",
          "Taxation of environmental land management and ecosystem service markets",
          "Tax credits: work out your childcare costs",
          "Tax avoidance - don't get caught out",
          "Tax structure and parameters statistics",
        ]

        expect(presenter.present).to eq(expected_responses)
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

  def example_es_response_with_autocomplete
    {
      "took" => 144,
      "timed_out" => false,
      "_shards" => {
        "total" => 9, "successful" => 9, "skipped" => 0, "failed" => 0
      },
      "hits" => {
        "total" => 49_659,
        "max_score" => 1_000_016.56,
        "hits" => [{
          "_index" => "govuk-2023-04-02t21-35-06z-a32d9f2c-8cae-490f-9cc6-f639ba022068",
          "_type" => "generic-document",
          "_id" => "/vehicle-tax",
          "_score" => 1_000_016.56,
          "_source" => {
            "link" => "/vehicle-tax", "format" => "transaction", "organisation_content_ids" => %w[70580624-93b5-4aed-823b-76042486c769], "description" => "Renew or tax your vehicle for the first time using a reminder letter, your log book or the green 'new keeper' slip - and how to tax if you do not have any documents", "title" => "Tax your vehicle", "mainstream_browse_page_content_ids" => %w[c4cbf7d1-c44e-4f47-b2c8-380e0609f8b0], "organisations" => %w[driver-and-vehicle-licensing-agency], "updated_at" => "2023-04-26T11:01:13.484+01:00", "popularity" => 0.058823529411764705, "public_timestamp" => "2017-12-07T12:54:39Z", "indexable_content" => "Tax your car, motorcycle or other vehicle using a reference number from:\n\na recent reminder (V11) or ‘last chance’ warning letter from DVLA\n\nyour vehicle log book (V5C) - it must be in your name\n\nthe green ‘new keeper’ slip from a log book if you’ve just bought it\n\nIf you do not have any of these documents, you’ll need to apply for a new log book.\n\nYou can pay by debit or credit card, or Direct Debit.\n\nYou must tax your vehicle even if you do not have to pay anything, for example if you’re exempt because you’re disabled.\n\nYou’ll need to meet all the legal obligations for drivers before you can drive.\n\nThis service is also available in Welsh.\n\n\n\nChange your car’s tax class to or from ‘disabled’\n\nYou may need to change your vehicle’s tax class, for example if either:\n\nyour car was previously used by a disabled person\n\nyou’re disabled and taxing your car for the first time\n\nYou can only apply at a Post Office.", "topical_events" => [], "document_type" => "edition", "world_locations" => []
          },
        }],
      },
      "autocomplete" => {
        "suggested_autocomplete" => [{
          "text" => "tax",
          "offset" => 0,
          "length" => 3,
          "options" => [
            {
              "text" => "Taxpayers given more",
              "_index" => "government-2021-08-12t23-23-51z-f0d661a8-7769-461e-8136-53c5d5c8d6a7",
              "_type" => "generic-document",
              "_id" => "/government/news/taxpayers-given-more-time-for-voluntary-national-insurance-contributions",
              "_score" => 234_584.0,
              "_source" => {
                "autocomplete" => {
                  "input" => "Taxpayers given more time for voluntary National Insurance contributions", "weight" => 234_584
                },
              },
            },
            {
              "text" => "Tax-free allowances ",
              "_index" => "detailed-2022-10-26t19-54-59z-342f3da4-1159-4433-898f-089272c6c25d",
              "_type" => "generic-document",
              "_id" => "/guidance/tax-free-allowances-on-property-and-trading-income",
              "_score" => 233_734.0,
              "_source" => {
                "autocomplete" => {
                  "input" => "Tax-free allowances on property and trading income", "weight" => 233_734
                },
              },
            },
            {
              "text" => "Tax treaties",
              "_index" => "government-2021-08-12t23-23-51z-f0d661a8-7769-461e-8136-53c5d5c8d6a7",
              "_type" => "generic-document",
              "_id" => "/government/collections/tax-treaties",
              "_score" => 233_235.0,
              "_source" => {
                "autocomplete" => {
                  "input" => "Tax treaties", "weight" => 233_235
                },
              },
            },
            {
              "text" => "Tax relief for resid",
              "_index" => "detailed-2022-10-26t19-54-59z-342f3da4-1159-4433-898f-089272c6c25d",
              "_type" => "generic-document",
              "_id" => "/guidance/changes-to-tax-relief-for-residential-landlords-how-its-worked-out-including-case-studies",
              "_score" => 231_379.0,
              "_source" => {
                "autocomplete" => {
                  "input" => "Tax relief for residential landlords: how it's worked out", "weight" => 231_379
                },
              },
            },
            {
              "text" => "Taxation of environm",
              "_index" => "government-2021-08-12t23-23-51z-f0d661a8-7769-461e-8136-53c5d5c8d6a7",
              "_type" => "generic-document",
              "_id" => "/government/consultations/taxation-of-environmental-land-management-and-ecosystem-service-markets",
              "_score" => 231_088.0,
              "_source" => {
                "autocomplete" => {
                  "input" => "Taxation of environmental land management and ecosystem service markets", "weight" => 231_088
                },
              },
            },
            {
              "text" => "Tax credits: work ou",
              "_index" => "govuk-2023-04-02t21-35-06z-a32d9f2c-8cae-490f-9cc6-f639ba022068",
              "_type" => "generic-document",
              "_id" => "/childcare-costs-for-tax-credits",
              "_score" => 229_788.0,
              "_source" => {
                "autocomplete" => {
                  "input" => "Tax credits: work out your childcare costs", "weight" => 229_788
                },
              },
            },
            {
              "text" => "Tax avoidance - don'",
              "_index" => "government-2021-08-12t23-23-51z-f0d661a8-7769-461e-8136-53c5d5c8d6a7",
              "_type" => "generic-document",
              "_id" => "/government/case-studies/tax-avoidance-dont-get-caught-out",
              "_score" => 229_608.0,
              "_source" => {
                "autocomplete" => {
                  "input" => "Tax avoidance - don't get caught out", "weight" => 229_608
                },
              },
            },
            {
              "text" => "Tax structure and pa",
              "_index" => "government-2021-08-12t23-23-51z-f0d661a8-7769-461e-8136-53c5d5c8d6a7",
              "_type" => "generic-document",
              "_id" => "/government/collections/tax-structure-and-parameters-statistics",
              "_score" => 229_231.0,
              "_source" => {
                "autocomplete" => {
                  "input" => "Tax structure and parameters statistics", "weight" => 229_231
                },
              },
            },
          ],
        }],
      },
    }
  end
end
