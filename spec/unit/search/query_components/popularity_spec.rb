require 'spec_helper'

RSpec.describe 'PopularityTest', tags: ['shoulda'] do
  it "add popularity to a query" do
    builder = QueryComponents::Popularity.new(search_query_params)

    result = builder.wrap({ some: 'query' })

    assert result.key?(:function_score)
  end

  context "with disabling of popularity" do
    it "disable popularity" do
      builder = QueryComponents::Popularity.new(
        search_query_params(debug: { disable_popularity: true })
      )

      result = builder.wrap({ some: 'query' })

      refute result.key?(:function_score)
    end
  end
end
