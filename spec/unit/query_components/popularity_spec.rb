require "spec_helper"

RSpec.describe QueryComponents::Popularity do
  it "add popularity to a query" do
    builder = described_class.new(search_query_params)

    result = builder.wrap({ some: "query" })

    expect(result).to be_key(:function_score)
  end

  context "with disabling of popularity" do
    it "disable popularity" do
      builder = described_class.new(
        search_query_params(debug: { disable_popularity: true }),
      )

      result = builder.wrap({ some: "query" })

      expect(result).not_to be_key(:function_score)
    end
  end

  context "with b variant of popularity" do
    it "makes popularity logarithmic" do
      builder = described_class.new(
        search_query_params(ab_tests: { popularity: "B" }),
      )

      result = builder.wrap({ some: "query" })

      expect(result).to eq(
        function_score: {
          boost_mode: :multiply,
          max_boost: 5,
          field_value_factor: {
            factor: described_class::POPULARITY_WEIGHT,
            field: "popularity_b",
            modifier: "log1p",
          },
          query: {
            some: "query",
          },
        },
      )
    end
  end
end
