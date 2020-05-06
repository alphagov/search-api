require "spec_helper"

RSpec.describe QueryComponents::Filter do
  def make_search_params(filters, include_withdrawn: true)
    Search::QueryParameters.new(filters: filters, debug: { include_withdrawn: include_withdrawn })
  end

  def make_date_filter_param(field_name, values)
    SearchParameterParser::DateFieldFilter.new(field_name, values, :filter, :any)
  end

  def make_boolean_filter_param(field_name, values)
    SearchParameterParser::BooleanFieldFilter.new(field_name, values, :filter, :any)
  end

  def text_filter(field_name, values, multivalue_query: :any)
    SearchParameterParser::TextFieldFilter.new(field_name, values, :filter, multivalue_query)
  end

  def reject_filter(field_name, values, multivalue_query: :any)
    SearchParameterParser::TextFieldFilter.new(field_name, values, :reject, multivalue_query)
  end

  context "search with one filter" do
    it "append the correct text filters" do
      builder = described_class.new(
        make_search_params([text_filter("organisations", %w[hm-magic])]),
      )

      result = builder.payload

      expect(result).to eq(bool: { must: ["terms" => { "organisations" => %w[hm-magic] }] })
    end

    it "append the correct date filters" do
      builder = described_class.new(
        make_search_params([make_date_filter_param("field_with_date", ["from:2014-04-01 00:00,to:2014-04-02 00:00"])]),
      )

      result = builder.payload

      expect(result).to eq(bool: { must: ["range" => { "field_with_date" => { "from" => "2014-04-01T00:00:00+00:00", "to" => "2014-04-02T00:00:00+00:00" } }] })
    end

    it "appends the correct boolean filters" do
      builder = described_class.new(
        make_search_params([make_boolean_filter_param("field_with_boolean", %w[true])]),
      )

      result = builder.payload

      expect(result).to eq({ bool: { must: [{ bool: { must: [{ term: { "field_with_boolean" => "true" } }] } }] } })
    end
  end

  context "search with a filter with multiple options" do
    it "have correct filter" do
      builder = described_class.new(
        make_search_params([text_filter("organisations", %w[hm-magic hmrc])]),
      )

      result = builder.payload

      expect(result).to eq(bool: { must: ["terms" => { "organisations" => %w[hm-magic hmrc] }] })
    end
  end

  context "with a filter and rejects" do
    it "have correct filter" do
      builder = described_class.new(
        make_search_params(
          [
            text_filter("organisations", %w[hm-magic hmrc]),
            reject_filter("mainstream_browse_pages", %w[benefits]),
          ],
        ),
      )

      result = builder.payload

      expect(result).to eq(
        bool: {
          must: [{ "terms" => { "organisations" => %w[hm-magic hmrc] } }],
          must_not: [{ "terms" => { "mainstream_browse_pages" => %w[benefits] } }],
        },
      )
    end
  end

  context "with all filter and rejects" do
    it "have correct filter" do
      builder = described_class.new(
        make_search_params(
          [
            text_filter("organisations", %w[hm-magic hmrc], multivalue_query: :all),
            reject_filter("mainstream_browse_pages", %w[benefits government], multivalue_query: :all),
          ],
        ),
      )

      result = builder.payload

      expect(result).to eq(
        bool: {
          must: [{ bool:
                    { must: [
                      {
                        term: { "organisations" => "hm-magic" },
                      },
                      {
                        term: { "organisations" => "hmrc" },
                      },
                    ] } }],
          must_not: [{ bool:
                       { must: [
                         {
                           term: { "mainstream_browse_pages" => "benefits" },
                         },
                         {
                           term: { "mainstream_browse_pages" => "government" },
                         },
                       ] } }],
        },
      )
    end
  end

  context "with multiple filters" do
    it "have correct filter" do
      builder = described_class.new(
        make_search_params(
          [
            text_filter("organisations", %w[hm-magic hmrc]),
            text_filter("mainstream_browse_pages", %w[levitation]),
          ],
        ),
      )

      result = builder.payload

      expect(result).to eq(
        bool: {
          must: [
            { "terms" => { "organisations" => %w[hm-magic hmrc] } },
            { "terms" => { "mainstream_browse_pages" => %w[levitation] } },
          ].compact,
        },
      )
    end
  end
end
