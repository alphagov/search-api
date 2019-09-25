require "spec_helper"

RSpec.describe QueryComponents::Popularity do
  it "add popularity to a query" do
    builder = described_class.new(search_query_params)

    result = builder.wrap({ some: "query" })

    expect(result.key?(:function_score)).to be_truthy
  end

  context "with disabling of popularity" do
    it "disable popularity" do
      builder = described_class.new(
        search_query_params(debug: { disable_popularity: true }),
      )

      result = builder.wrap({ some: "query" })

      expect(result.key?(:function_score)).to be_falsey
    end
  end
end
