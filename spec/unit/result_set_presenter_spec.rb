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
    }, {
      "_index" => "govuk-2014-03-19t14:35:28z-6472f975-dc38-49a5-98eb-c498e619650c",
      _type: "edition",
      _id: "/duty-relief-for-imports-and-exports",
      "_score" => 0.49672604,
      "_source" => {
        "description" => "Schemes that offer reduced or zero rate duty and VAT for imports and exports",
        "title" => "Duty relief for imports and exports",
        "link" => "/duty-relief-for-imports-and-exports",
      },
    }, {
      "_index" => "govuk-2014-03-19t14:35:27z-27e2831f-bd14-47d8-9c7a-3017e213efe3",
      _type: "edition",
      _id: "/dairy-farming-and-schemes",
      "_score" => 0.34655035,
      "_source" => {
        "title" => "Dairy farming and schemes",
        "link" => "/dairy-farming-and-schemes",
        "policy_areas" => ["farming"],
      },
    }]
  end

  def sample_es_response(extra = {})
    {
      "hits" => {
        "hits" => sample_docs,
        "total" => 3,
      }
    }.merge(extra)
  end

  def sample_aggregate_data
    {
      "organisations" => {
        "filtered_aggregations" => {
          "buckets" => [
            { "key" => "hm-magic", "doc_count" => 7 },
            { "key" => "hmrc", "doc_count" => 5 },
          ],
        }
      },
      "organisations_with_missing_value" => {
        "filtered_aggregations" => {
          "doc_count" => 8
        }
      }
    }
  end

  def sample_aggregate_data_with_policy_areas
    {
      "organisations" => {
        "filtered_aggregations" => {
          "buckets" => [
            { "key" => "hm-magic", "doc_count" => 7 },
            { "key" => "hmrc", "doc_count" => 5 },
          ],
        }
      },
      "organisations_with_missing_value" => {
        "filtered_aggregations" => {
          "doc_count" => 8
        }
      },
      "policy_areas" => {
        "filtered_aggregations" => {
          "buckets" => [
            { "key" => "farming", "doc_count" => 4 },
            { "key" => "unknown_topic", "doc_count" => 5 },
          ],
        }
      },
      "policy_areas_with_missing_value" => {
        "filtered_aggregations" => {
          "doc_count" => 3,
        }
      },
    }
  end

  def sample_org_registry
    {
      "hm-magic" => {
        "link" => "/government/departments/hm-magic",
        "title" => "Ministry of Magic"
      },
      "hmrc" => {
        "link" => "/government/departments/hmrc",
        "title" => "HMRC"
      }
    }
  end

  def aggregate_response_magic
    {
      value: {
        "link" => "/government/departments/hm-magic",
        "title" => "Ministry of Magic",
        "slug" => "hm-magic",
      },
      documents: 7,
    }
  end

  def aggregate_response_hmrc
    {
      value: {
        "link" => "/government/departments/hmrc",
        "title" => "HMRC",
        "slug" => "hmrc",
      },
      documents: 5,
    }
  end

  def aggregate_params(requested, options = {})
    {
      requested: requested,
      order: SearchParameterParser::DEFAULT_AGGREGATE_SORT,
      scope: :exclude_field_filter,
    }.merge(options)
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
      aggregate_examples: options.fetch(:aggregate_examples, {}),
      schema: options.fetch(:schema, nil)
    )
  end

  context "no results" do
    before do
      results = {
        "hits" => {
          "hits" => [],
          "total" => 0
        }
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

    it "have no aggregates" do
      expect(@output[:aggregates]).to eq({})
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
        doc_fields = result.keys - [:_type, :_id]
        returned_fields = result.keys - [:esscore, :_type, :_id]
        expect(doc_fields).to eq(returned_fields)
      end
    end
  end

  context "results with no fields" do
    before do
      @empty_result = sample_docs.first.tap {|doc|
        doc["fields"] = nil
      }
      response = sample_es_response.tap {|es_response|
        es_response["hits"]["hits"] = [@empty_result]
      }

      @output = described_class.new(
        search_params: Search::QueryParameters.new(
          start: 0,
          aggregate_name: :aggregates,
        ),
        es_response: response
      ).present
    end

    it "return only basic metadata of fields" do
      expected_keys = [:index, :es_score, :_id, :elasticsearch_type, :document_type]

      expect(expected_keys).to eq(@output[:results].first.keys)
    end
  end

  context "results with a registry" do
    before do
      policy_area_registry = {
        "farming" => {
          "link" => "/government/topics/farming",
          "title" => "Farming"
        }
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
        doc_fields = result.keys - [:_type, :_id]
        returned_fields = result.keys - [:esscore, :_type, :_id]
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

  context "results with aggregates" do
    before do
      @output = described_class.new(
        search_params: Search::QueryParameters.new(
          start: 0,
          aggregates: { "organisations" => aggregate_params(1) },
          aggregate_name: :aggregates,
        ),
        es_response: sample_es_response("aggregations" => sample_aggregate_data),
      ).present
    end

    it "have aggregates" do
      expect(@output.keys).to include(:aggregates)
    end

    it "have correct number of aggregates" do
      expect(@output[:aggregates].length).to eq(1)
    end

    it "have correct number of aggregate values" do
      expect(@output[:aggregates]["organisations"][:options].length).to eq(1)
    end

    it "include requested aggregate scope" do
      aggregate = @output[:aggregates]["organisations"]
      expect(:exclude_field_filter).to eq(aggregate[:scope])
    end

    it "have correct top aggregate value value" do
      expect(
        value: { "slug" => "hm-magic" },
        documents: 7,
      ).to eq @output[:aggregates]["organisations"][:options][0]
    end

    it "have correct number of documents with no value" do
      expect(@output[:aggregates]["organisations"][:documents_with_no_value]).to eq(8)
    end

    it "have correct total number of options" do
      expect(@output[:aggregates]["organisations"][:total_options]).to eq(2)
    end

    it "have correct number of missing options" do
      expect(@output[:aggregates]["organisations"][:missing_options]).to eq(1)
    end
  end

  context "results with aggregates and a filter applied" do
    before do
      @output = described_class.new(
        search_params: Search::QueryParameters.new(
          start: 0,
          filters: [text_filter("organisations", ["hmrc"])],
          aggregates: { "organisations" => aggregate_params(2) },
          aggregate_name: :aggregates,
        ),
        es_response: sample_es_response("aggregations" => sample_aggregate_data),
      ).present
    end

    it "have aggregates" do
      expect(@output.keys).to include(:aggregates)
    end

    it "have correct number of aggregates" do
      expect(@output[:aggregates].length).to eq(1)
    end

    it "have correct number of aggregate values" do
      expect(@output[:aggregates]["organisations"][:options].length).to eq(2)
    end

    it "have selected aggregate first" do
      expect(
        value: { "slug" => "hmrc" },
        documents: 5,
      ).to eq @output[:aggregates]["organisations"][:options][0]
    end

    it "have unapplied aggregate value second" do
      expect(
        value: { "slug" => "hm-magic" },
        documents: 7,
      ).to eq @output[:aggregates]["organisations"][:options][1]
    end

    it "have correct number of documents with no value" do
      expect(@output[:aggregates]["organisations"][:documents_with_no_value]).to eq(8)
    end

    it "have correct total number of options" do
      expect(@output[:aggregates]["organisations"][:total_options]).to eq(2)
    end

    it "have correct number of missing options" do
      expect(@output[:aggregates]["organisations"][:missing_options]).to eq(0)
    end
  end

  context "results with aggregates and a filter which matches nothing applied" do
    before do
      @output = described_class.new(
        search_params: Search::QueryParameters.new(
          start: 0,
          filters: [text_filter("organisations", ["hm-cheesemakers"])],
          aggregates: { "organisations" => aggregate_params(1) },
          aggregate_name: :aggregates,
        ),
        es_response: sample_es_response("aggregations" => sample_aggregate_data),
      ).present
    end

    it "have aggregates" do
      expect(@output.keys).to include(:aggregates)
    end

    it "have correct number of aggregates" do
      expect(@output[:aggregates].length).to eq(1)
    end

    it "have correct number of aggregate values" do
      expect(@output[:aggregates]["organisations"][:options].length).to eq(2)
    end

    it "have selected aggregate first" do
      expect(
        value: { "slug" => "hm-cheesemakers" },
        documents: 0,
      ).to eq @output[:aggregates]["organisations"][:options][0]
    end

    it "have unapplied aggregate value second" do
      expect(
        value: { "slug" => "hm-magic" },
        documents: 7,
      ).to eq @output[:aggregates]["organisations"][:options][1]
    end

    it "have correct number of documents with no value" do
      expect(@output[:aggregates]["organisations"][:documents_with_no_value]).to eq(8)
    end

    it "have correct total number of options" do
      expect(@output[:aggregates]["organisations"][:total_options]).to eq(2)
    end

    it "have correct number of missing options" do
      expect(@output[:aggregates]["organisations"][:missing_options]).to eq(1)
    end
  end

  context "results with aggregate counting only" do
    before do
      @output = described_class.new(
        search_params: Search::QueryParameters.new(
          start: 0,
          aggregates: { "organisations" => aggregate_params(0) },
          aggregate_name: :aggregates,
        ),
        es_response: sample_es_response("aggregations" => sample_aggregate_data),
      ).present
    end

    it "have correct number of aggregates" do
      expect(@output[:aggregates].length).to eq(1)
    end

    it "have no aggregate values" do
      expect(@output[:aggregates]["organisations"][:options].length).to eq(0)
    end

    it "have correct number of documents with no value" do
      expect(@output[:aggregates]["organisations"][:documents_with_no_value]).to eq(8)
    end

    it "have correct total number of options" do
      expect(@output[:aggregates]["organisations"][:total_options]).to eq(2)
    end

    it "have correct number of missing options" do
      expect(@output[:aggregates]["organisations"][:missing_options]).to eq(2)
    end
  end

  context "results with aggregates sorted by ascending count" do
    before do
      org_registry = sample_org_registry
      @output = search_presenter(
        es_response: { "aggregations" => sample_aggregate_data },
        aggregates: { "organisations" => aggregate_params(10, order: [[:count, 1]]) },
        org_registry: org_registry
      ).present
    end

    it "have aggregates sorted by ascending count" do
      expect([
        aggregate_response_hmrc,
        aggregate_response_magic,
      ]).to eq @output[:aggregates]["organisations"][:options]
    end
  end

  context "results with aggregates sorted by descending count" do
    before do
      org_registry = sample_org_registry
      @output = search_presenter(
        es_response: { "aggregations" => sample_aggregate_data },
        aggregates: { "organisations" => aggregate_params(10, order: [[:count, -1]]) },
        org_registry: org_registry
      ).present
    end

    it "have aggregates sorted by descending count" do
      expect([
        aggregate_response_magic,
        aggregate_response_hmrc,
      ]).to eq @output[:aggregates]["organisations"][:options]
    end
  end

  context "results with aggregates sorted by ascending slug" do
    before do
      org_registry = sample_org_registry
      @output = search_presenter(
        es_response: { "aggregations" => sample_aggregate_data },
        aggregates: { "organisations" => aggregate_params(10, order: [[:"value.slug", 1]]) },
        aggregate_name: :aggregates,
        org_registry: org_registry
      ).present
    end

    it "have aggregates sorted by ascending slug" do
      expect([
        aggregate_response_magic,
        aggregate_response_hmrc,
      ]).to eq @output[:aggregates]["organisations"][:options]
    end
  end

  context "results with aggregates sorted by ascending link" do
    before do
      org_registry = sample_org_registry
      @output = search_presenter(
        es_response: { "aggregations" => sample_aggregate_data },
        aggregates: { "organisations" => aggregate_params(10, order: [[:"value.link", 1]]) },
        org_registry: org_registry
      ).present
    end

    it "have aggregates sorted by ascending link" do
      expect([
        aggregate_response_magic,
        aggregate_response_hmrc,
      ]).to eq @output[:aggregates]["organisations"][:options]
    end
  end

  context "results with aggregates sorted by ascending title" do
    before do
      org_registry = sample_org_registry
      @output = search_presenter(
        es_response: { "aggregations" => sample_aggregate_data },
        aggregates: { "organisations" => aggregate_params(10, order: [[:"value.title", 1]]) },
        org_registry: org_registry
      ).present
    end

    it "have aggregates sorted by ascending title" do
      expect([
        aggregate_response_hmrc,
        aggregate_response_magic,
      ]).to eq @output[:aggregates]["organisations"][:options]
    end
  end

  context "results with aggregates and an org registry" do
    before do
      org_registry = sample_org_registry

      @output = described_class.new(
        search_params: Search::QueryParameters.new(
          start: 0,
          aggregates: { "organisations" => aggregate_params(1), "policy_areas" => aggregate_params(1) },
          aggregate_name: :aggregates,
        ),
        es_response: sample_es_response("aggregations" => sample_aggregate_data_with_policy_areas),
        registries: { organisations: org_registry },
      ).present
    end

    it "have aggregates" do
      expect(@output.keys).to include(:aggregates)
    end

    it "have correct number of aggregates" do
      expect(@output[:aggregates].length).to eq(2)
    end

    it "have correct number of aggregate values" do
      expect(@output[:aggregates]["organisations"][:options].length).to eq(1)
      expect(@output[:aggregates]["policy_areas"][:options].length).to eq(1)
    end

    it "have org aggregate value expanded" do
      expect(
        value: {
          "link" => "/government/departments/hm-magic",
          "title" => "Ministry of Magic",
          "slug" => "hm-magic",
        },
        documents: 7,
      ).to eq @output[:aggregates]["organisations"][:options][0]
    end

    it "have topic aggregate value un-expanded" do
      expect(
        value: { "slug" => "unknown_topic" },
        documents: 5,
      ).to eq @output[:aggregates]["policy_areas"][:options][0]
    end

    it "have correct number of documents with no value" do
      expect(@output[:aggregates]["organisations"][:documents_with_no_value]).to eq(8)
      expect(@output[:aggregates]["policy_areas"][:documents_with_no_value]).to eq(3)
    end

    it "have correct total number of options" do
      expect(@output[:aggregates]["organisations"][:total_options]).to eq(2)
      expect(@output[:aggregates]["policy_areas"][:total_options]).to eq(2)
    end

    it "have correct number of missing options" do
      expect(@output[:aggregates]["organisations"][:missing_options]).to eq(1)
      expect(@output[:aggregates]["policy_areas"][:missing_options]).to eq(1)
    end
  end

  context "results with aggregate examples" do
    before do
      org_registry = sample_org_registry

      @output = described_class.new(
        search_params: Search::QueryParameters.new(
          start: 0,
          aggregates: { "organisations" => aggregate_params(1) },
          aggregate_name: :aggregates,
        ),
        es_response: sample_es_response("aggregations" => sample_aggregate_data),
        registries: { organisations: org_registry },
        aggregate_examples: { "organisations" => {
          "hm-magic" => {
            "total" => 1,
            "examples" => [{ "title" => "Ministry of Magic" }],
          }
        } }
      ).present
    end

    it "have aggregates" do
      expect(@output.keys).to include(:aggregates)
    end

    it "have correct number of aggregates" do
      expect(@output[:aggregates].length).to eq(1)
    end

    it "have correct number of aggregate values" do
      expect(@output[:aggregates]["organisations"][:options].length).to eq(1)
    end

    it "have org aggregate value expanded, and include examples" do
      expect(
        value: {
          "link" => "/government/departments/hm-magic",
          "title" => "Ministry of Magic",
          "slug" => "hm-magic",
          "example_info" => {
            "total" => 1,
            "examples" => [
              { "title" => "Ministry of Magic" },
            ],
          },
        },
        documents: 7,
      ).to eq @output[:aggregates]["organisations"][:options][0]
    end

    it "have correct number of documents with no value" do
      expect(@output[:aggregates]["organisations"][:documents_with_no_value]).to eq(8)
    end

    it "have correct total number of options" do
      expect(@output[:aggregates]["organisations"][:total_options]).to eq(2)
    end

    it "have correct number of missing options" do
      expect(@output[:aggregates]["organisations"][:missing_options]).to eq(1)
    end
  end

  def text_filter(field_name, values)
    SearchParameterParser::TextFieldFilter.new(field_name, values, :filter, :any)
  end
end
