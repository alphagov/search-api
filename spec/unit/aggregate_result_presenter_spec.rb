require "spec_helper"

RSpec.describe Search::AggregateResultPresenter do
  def sample_aggregate_data
    {
      "organisations" => {
        "filtered_aggregations" => {
          "buckets" => [
            { "key" => "hm-magic", "doc_count" => 7 },
            { "key" => "hmrc", "doc_count" => 5 },
          ],
        },
      },
      "organisations_with_missing_value" => {
        "filtered_aggregations" => {
          "doc_count" => 8,
        },
      },
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
        },
      },
      "organisations_with_missing_value" => {
        "filtered_aggregations" => {
          "doc_count" => 8,
        },
      },
      "policy_areas" => {
        "filtered_aggregations" => {
          "buckets" => [
            { "key" => "farming", "doc_count" => 4 },
            { "key" => "unknown_topic", "doc_count" => 5 },
          ],
        },
      },
      "policy_areas_with_missing_value" => {
        "filtered_aggregations" => {
          "doc_count" => 3,
        },
      },
    }
  end

  def sample_org_registry
    {
      "hm-magic" => {
        "link" => "/government/departments/hm-magic",
        "title" => "Ministry of Magic",
      },
      "hmrc" => {
        "link" => "/government/departments/hmrc",
        "title" => "HMRC",
      },
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
      requested:,
      order: SearchParameterParser::DEFAULT_AGGREGATE_SORT,
      scope: :exclude_field_filter,
    }.merge(options)
  end

  def presented_aggregates(es_response: {}, aggregates: {}, registries: {}, filters: [])
    described_class.new(
      es_response,
      Search::QueryParameters.new(
        start: 0,
        aggregate_name: :aggregates,
        aggregates:,
        filters:,
      ),
      registries,
    ).presented_aggregates
  end

  context "no results" do
    before do
      @output = presented_aggregates
    end

    it "have no aggregates" do
      expect(@output).to eq({})
    end
  end

  context "results with aggregates" do
    before do
      @output = presented_aggregates(
        es_response: sample_aggregate_data,
        aggregates: { "organisations" => aggregate_params(1) },
      )
    end

    it "have correct number of aggregates" do
      expect(@output.length).to eq(1)
    end

    it "have correct number of aggregate values" do
      expect(@output["organisations"][:options].length).to eq(1)
    end

    it "include requested aggregate scope" do
      aggregate = @output["organisations"]
      expect(:exclude_field_filter).to eq(aggregate[:scope])
    end

    it "have correct top aggregate value value" do
      expect(
        value: { "slug" => "hm-magic" },
        documents: 7,
      ).to eq @output["organisations"][:options][0]
    end

    it "have correct number of documents with no value" do
      expect(@output["organisations"][:documents_with_no_value]).to eq(8)
    end

    it "have correct total number of options" do
      expect(@output["organisations"][:total_options]).to eq(2)
    end

    it "have correct number of missing options" do
      expect(@output["organisations"][:missing_options]).to eq(1)
    end
  end

  context "results with aggregates and a filter applied" do
    before do
      @output = presented_aggregates(
        es_response: sample_aggregate_data,
        aggregates: { "organisations" => aggregate_params(2) },
        filters: [text_filter("organisations", %w[hmrc])],
      )
    end

    it "have correct number of aggregates" do
      expect(@output.length).to eq(1)
    end

    it "have correct number of aggregate values" do
      expect(@output["organisations"][:options].length).to eq(2)
    end

    it "have selected aggregate first" do
      expect(
        value: { "slug" => "hmrc" },
        documents: 5,
      ).to eq @output["organisations"][:options][0]
    end

    it "have unapplied aggregate value second" do
      expect(
        value: { "slug" => "hm-magic" },
        documents: 7,
      ).to eq @output["organisations"][:options][1]
    end

    it "have correct number of documents with no value" do
      expect(@output["organisations"][:documents_with_no_value]).to eq(8)
    end

    it "have correct total number of options" do
      expect(@output["organisations"][:total_options]).to eq(2)
    end

    it "have correct number of missing options" do
      expect(@output["organisations"][:missing_options]).to eq(0)
    end
  end

  context "results with aggregates and a filter which matches nothing applied" do
    before do
      @output = presented_aggregates(
        es_response: sample_aggregate_data,
        aggregates: { "organisations" => aggregate_params(1) },
        filters: [text_filter("organisations", %w[hm-cheesemakers])],
      )
    end

    it "have correct number of aggregates" do
      expect(@output.length).to eq(1)
    end

    it "have correct number of aggregate values" do
      expect(@output["organisations"][:options].length).to eq(2)
    end

    it "have selected aggregate first" do
      expect(
        value: { "slug" => "hm-cheesemakers" },
        documents: 0,
      ).to eq @output["organisations"][:options][0]
    end

    it "have unapplied aggregate value second" do
      expect(
        value: { "slug" => "hm-magic" },
        documents: 7,
      ).to eq @output["organisations"][:options][1]
    end

    it "have correct number of documents with no value" do
      expect(@output["organisations"][:documents_with_no_value]).to eq(8)
    end

    it "have correct total number of options" do
      expect(@output["organisations"][:total_options]).to eq(2)
    end

    it "have correct number of missing options" do
      expect(@output["organisations"][:missing_options]).to eq(1)
    end
  end

  context "results with aggregate counting only" do
    before do
      @output = presented_aggregates(
        es_response: sample_aggregate_data,
        aggregates: { "organisations" => aggregate_params(0) },
      )
    end

    it "have correct number of aggregates" do
      expect(@output.length).to eq(1)
    end

    it "have no aggregate values" do
      expect(@output["organisations"][:options].length).to eq(0)
    end

    it "have correct number of documents with no value" do
      expect(@output["organisations"][:documents_with_no_value]).to eq(8)
    end

    it "have correct total number of options" do
      expect(@output["organisations"][:total_options]).to eq(2)
    end

    it "have correct number of missing options" do
      expect(@output["organisations"][:missing_options]).to eq(2)
    end
  end

  context "results with aggregates sorted by ascending count" do
    before do
      @output = presented_aggregates(
        es_response: sample_aggregate_data,
        aggregates: { "organisations" => aggregate_params(10, order: [[:count, 1]]) },
        registries: { organisations: sample_org_registry },
      )
    end

    it "have aggregates sorted by ascending count" do
      expect([
        aggregate_response_hmrc,
        aggregate_response_magic,
      ]).to eq @output["organisations"][:options]
    end
  end

  context "results with aggregates sorted by descending count" do
    before do
      @output = presented_aggregates(
        es_response: sample_aggregate_data,
        aggregates: { "organisations" => aggregate_params(10, order: [[:count, -1]]) },
        registries: { organisations: sample_org_registry },
      )
    end

    it "have aggregates sorted by descending count" do
      expect([
        aggregate_response_magic,
        aggregate_response_hmrc,
      ]).to eq @output["organisations"][:options]
    end
  end

  context "results with aggregates sorted by ascending slug" do
    before do
      @output = presented_aggregates(
        es_response: sample_aggregate_data,
        aggregates: { "organisations" => aggregate_params(10, order: [[:"value.slug", 1]]) },
        registries: { organisations: sample_org_registry },
      )
    end

    it "have aggregates sorted by ascending slug" do
      expect([
        aggregate_response_magic,
        aggregate_response_hmrc,
      ]).to eq @output["organisations"][:options]
    end
  end

  context "results with aggregates sorted by ascending link" do
    before do
      @output = presented_aggregates(
        es_response: sample_aggregate_data,
        aggregates: { "organisations" => aggregate_params(10, order: [[:"value.link", 1]]) },
        registries: { organisations: sample_org_registry },
      )
    end

    it "have aggregates sorted by ascending link" do
      expect([
        aggregate_response_magic,
        aggregate_response_hmrc,
      ]).to eq @output["organisations"][:options]
    end
  end

  context "results with aggregates sorted by ascending title" do
    before do
      @output = presented_aggregates(
        es_response: sample_aggregate_data,
        aggregates: { "organisations" => aggregate_params(10, order: [[:"value.title", 1]]) },
        registries: { organisations: sample_org_registry },
      )
    end

    it "have aggregates sorted by ascending title" do
      expect([
        aggregate_response_hmrc,
        aggregate_response_magic,
      ]).to eq @output["organisations"][:options]
    end
  end

  context "results with aggregates and an org registry" do
    before do
      @output = presented_aggregates(
        es_response: sample_aggregate_data_with_policy_areas,
        aggregates: { "organisations" => aggregate_params(1), "policy_areas" => aggregate_params(1) },
        registries: { organisations: sample_org_registry },
      )
    end

    it "have correct number of aggregates" do
      expect(@output.length).to eq(2)
    end

    it "have correct number of aggregate values" do
      expect(@output["organisations"][:options].length).to eq(1)
      expect(@output["policy_areas"][:options].length).to eq(1)
    end

    it "have org aggregate value expanded" do
      expect(
        value: {
          "link" => "/government/departments/hm-magic",
          "title" => "Ministry of Magic",
          "slug" => "hm-magic",
        },
        documents: 7,
      ).to eq @output["organisations"][:options][0]
    end

    it "have topic aggregate value un-expanded" do
      expect(
        value: { "slug" => "unknown_topic" },
        documents: 5,
      ).to eq @output["policy_areas"][:options][0]
    end

    it "have correct number of documents with no value" do
      expect(@output["organisations"][:documents_with_no_value]).to eq(8)
      expect(@output["policy_areas"][:documents_with_no_value]).to eq(3)
    end

    it "have correct total number of options" do
      expect(@output["organisations"][:total_options]).to eq(2)
      expect(@output["policy_areas"][:total_options]).to eq(2)
    end

    it "have correct number of missing options" do
      expect(@output["organisations"][:missing_options]).to eq(1)
      expect(@output["policy_areas"][:missing_options]).to eq(1)
    end
  end

  context "results with aggregate examples" do
    before do
      @output = presented_aggregates(
        es_response: sample_aggregate_data,
        aggregates: { "organisations" => aggregate_params(1) },
        registries: { organisations: sample_org_registry },
      )
      described_class.merge_examples(
        @output,
        {
          "organisations" => {
            "hm-magic" => {
              "total" => 1,
              "examples" => [{ "title" => "Ministry of Magic" }],
            },
          },
        },
      )
    end

    it "have correct number of aggregates" do
      expect(@output.length).to eq(1)
    end

    it "have correct number of aggregate values" do
      expect(@output["organisations"][:options].length).to eq(1)
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
      ).to eq @output["organisations"][:options][0]
    end

    it "have correct number of documents with no value" do
      expect(@output["organisations"][:documents_with_no_value]).to eq(8)
    end

    it "have correct total number of options" do
      expect(@output["organisations"][:total_options]).to eq(2)
    end

    it "have correct number of missing options" do
      expect(@output["organisations"][:missing_options]).to eq(1)
    end
  end

  def text_filter(field_name, values)
    SearchParameterParser::TextFieldFilter.new(field_name, values, :filter, :any)
  end
end
