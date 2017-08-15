require 'spec_helper'

RSpec.describe 'BestBetsTest', tags: ['shoulda'] do
  before do
    IndexHelpers.stub_elasticsearch_settings
  end

  context "when best bets is disabled in debug" do
    it "return the query without modification" do
      builder = QueryComponents::BestBets.new(
        metasearch_index: SearchConfig.instance.metasearch_index,
        search_params: Search::QueryParameters.new(debug: { disable_best_bets: true })
      )

      result = builder.wrap('QUERY')

      assert_equal result, 'QUERY'
    end
  end

  context "with a single best bet url" do
    it "include the ID of the document in the results" do
      builder = QueryComponents::BestBets.new(metasearch_index: SearchConfig.instance.metasearch_index)
      builder.stubs best_bets: { 1 => ['/best-bet'] }

      result = builder.wrap('QUERY')

      expected = { bool: { should: ['QUERY', { function_score: { query: { ids: { values: ["/best-bet"] } }, boost_factor: 1000000 } }] } }
      assert_equal expected, result
    end
  end

  context "with two best bet urls on different positions" do
    it "include IDs of the documents in the results" do
      builder = QueryComponents::BestBets.new(metasearch_index: SearchConfig.instance.metasearch_index)
      builder.stubs best_bets: { 1 => ['/best-bet'], 2 => ['/other-best-bet'] }

      result = builder.wrap('QUERY')

      expected = {
        bool: {
          should: ['QUERY',
                   { function_score: { query: { ids: { values: ["/best-bet"] } }, boost_factor: 2000000 } },
                   { function_score: { query: { ids: { values: ["/other-best-bet"] } }, boost_factor: 1000000 } }
            ]
        }
      }

      assert_equal expected, result
    end
  end

  context "with two best bet urls on the same position" do
    it "include IDs of the documents in the results" do
      builder = QueryComponents::BestBets.new(metasearch_index: SearchConfig.instance.metasearch_index)
      builder.stubs best_bets: { 1 => ['/best-bet', '/other-best-bet'] }

      result = builder.wrap('QUERY')

      expected = { bool: { should: ['QUERY', { function_score: { query: { ids: { values: ["/best-bet", "/other-best-bet"] } }, boost_factor: 1000000 } }] } }
      assert_equal expected, result
    end
  end

  context "with a 'worst bet'" do
    it "completely exclude the documents from the results" do
      builder = QueryComponents::BestBets.new(metasearch_index: SearchConfig.instance.metasearch_index)
      builder.stubs worst_bets: ['/worst-bet', '/other-worst-bet']

      result = builder.wrap({})

      expected = { bool: { should: [{}], must_not: [{ ids: { values: ["/worst-bet", "/other-worst-bet"] } }] } }
      assert_equal expected, result
    end
  end
end
