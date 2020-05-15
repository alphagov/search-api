require "spec_helper"

RSpec.describe Search::ResultSetPresenter do
  def sample_docs
    [{
      "_index" => "government-2014-03-19t14:35:28z-a05cfc73-933a-41c7-adc0-309a715baf09",
      _type: "edition",
      _id: "/government/publications/staffordshire-cheese",
      "_score" => 3.0514863,
      "_source" => {
        "description" => "Staffordshire Cheese Product of Designated Origin (PDO) and Staffordshire Organic Cheese.",
        "title" => "Staffordshire Cheese",
        "link" => "/government/publications/staffordshire-cheese",
      },
    },
     {
       "_index" => "govuk-2014-03-19t14:35:28z-6472f975-dc38-49a5-98eb-c498e619650c",
       _type: "edition",
       _id: "/duty-relief-for-imports-and-exports",
       "_score" => 0.49672604,
       "_source" => {
         "description" => "Schemes that offer reduced or zero rate duty and VAT for imports and exports",
         "title" => "Duty relief for imports and exports",
         "link" => "/duty-relief-for-imports-and-exports",
       },
     },
     {
       "_index" => "govuk-2014-03-19t14:35:27z-27e2831f-bd14-47d8-9c7a-3017e213efe3",
       _type: "edition",
       _id: "/dairy-farming-and-schemes",
       "_score" => 0.34655035,
       "_source" => {
         "title" => "Dairy farming and schemes",
         "link" => "/dairy-farming-and-schemes",
         "policy_areas" => %w[farming],
       },
     }]
  end

  def sample_es_response(extra = {})
    {
      "hits" => {
        "hits" => sample_docs,
        "total" => 3,
      },
    }.merge(extra)
  end

  def search_presenter(options)
    org_registry = options[:org_registry]
    described_class.new(
      search_params: Search::QueryParameters.new(
        start: options.fetch(:start, 0),
        filters: options.fetch(:filters, []),
        aggregates: options.fetch(:aggregates, {}),
        aggregate_name: :aggregates,
      ),
      es_response: sample_es_response(options.fetch(:es_response, {})),
      registries: org_registry.nil? ? {} : { organisations: org_registry },
      presented_aggregates: options.fetch(:presented_aggregates, {}),
      schema: options.fetch(:schema, nil),
    )
  end

  context "no results" do
    before do
      results = {
        "hits" => {
          "hits" => [],
          "total" => 0,
        },
      }
      @output = described_class.new(
        search_params: Search::QueryParameters.new(
          start: 0,
          aggregate_name: :aggregates,
        ),
        es_response: results,
      ).present
    end

    it "present empty list of results" do
      expect(@output[:results]).to eq([])
    end

    it "have total of 0" do
      expect(@output[:total]).to eq(0)
    end
  end

  context "results with no registries" do
    before do
      @output = described_class.new(
        search_params: Search::QueryParameters.new(
          start: 0,
          aggregate_name: :aggregates,
        ),
        es_response: sample_es_response,
      ).present
    end

    it "have correct total" do
      expect(@output[:total]).to eq(3)
    end

    it "have correct number of results" do
      expect(@output[:results].length).to eq(3)
    end

    it "have short index names" do
      @output[:results].each do |result|
        expect(%w[govuk government]).to include(result[:index])
      end
    end

    it "have the score in es score" do
      @output[:results].zip(sample_docs).each do |result, doc|
        expect(result.keys).not_to include("_score")
        expect(result[:es_score]).not_to be_nil
        expect(doc["_score"]).to eq(result[:es_score])
      end
    end

    it "have only the fields returned from search engine" do
      @output[:results].zip(sample_docs).each do |result, _doc|
        doc_fields = result.keys - %i[_type _id]
        returned_fields = result.keys - %i[esscore _type _id]
        expect(doc_fields).to eq(returned_fields)
      end
    end
  end

  context "results with no fields" do
    before do
      @empty_result = sample_docs.first.tap do |doc|
        doc["fields"] = nil
      end
      response = sample_es_response.tap do |es_response|
        es_response["hits"]["hits"] = [@empty_result]
      end

      @output = described_class.new(
        search_params: Search::QueryParameters.new(
          start: 0,
          aggregate_name: :aggregates,
        ),
        es_response: response,
      ).present
    end

    it "return only basic metadata of fields" do
      expected_keys = %i[index es_score _id elasticsearch_type document_type]

      expect(expected_keys).to eq(@output[:results].first.keys)
    end
  end

  context "results with a registry" do
    before do
      policy_area_registry = {
        "farming" => {
          "link" => "/government/topics/farming",
          "title" => "Farming",
        },
      }

      @output = described_class.new(
        search_params: Search::QueryParameters.new(
          start: 0,
          return_fields: %w[policy_areas],
          aggregate_name: :aggregates,
        ),
        es_response: sample_es_response,
        registries: { policy_areas: policy_area_registry },
      ).present
    end

    it "have correct total" do
      expect(@output[:total]).to eq(3)
    end

    it "have correct number of results" do
      expect(@output[:results].length).to eq(3)
    end

    it "have short index names" do
      @output[:results].each do |result|
        expect(%w[govuk government]).to include(result[:index])
      end
    end

    it "have the score in es score" do
      @output[:results].zip(sample_docs).each do |result, doc|
        expect(result.keys).not_to include("_score")
        expect(result[:es_score]).not_to be_nil
        expect(doc["_score"]).to eq(result[:es_score])
      end
    end

    it "have only the fields returned from search engine" do
      @output[:results].zip(sample_docs).each do |result, _doc|
        doc_fields = result.keys - %i[_type _id]
        returned_fields = result.keys - %i[esscore _type _id]
        expect(doc_fields).to eq(returned_fields)
      end
    end

    it "have the expanded topic" do
      result = @output[:results][2]
      expect([{
        "link" => "/government/topics/farming",
        "title" => "Farming",
        "slug" => "farming",
      }]).to eq result["policy_areas"]
    end
  end

  context "reranked results" do
    before do
      @results = {
        "hits" => {
          "hits" => [],
          "total" => 0,
        },
      }
    end

    it "sets reranked: false" do
      output = described_class.new(
        search_params: Search::QueryParameters.new(
          start: 0,
          aggregate_name: :aggregates,
        ),
        es_response: @results,
        reranked: false,
      ).present

      expect(output[:reranked]).to eq(false)
    end

    it "sets reranked: true" do
      output = described_class.new(
        search_params: Search::QueryParameters.new(
          start: 0,
          aggregate_name: :aggregates,
        ),
        es_response: @results,
        reranked: false,
      ).present

      expect(output[:reranked]).to eq(false)
    end
  end
end
