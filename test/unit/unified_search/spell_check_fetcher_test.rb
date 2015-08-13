require "test_helper"
require "unified_search/spell_check_fetcher"
require "search_config"

class UnifiedSearch::SpellCheckFetcherTest < ShouldaUnitTestCase
  context "#es_response" do
    should "return the raw elasticsearch response" do
      UnifiedSearch::SuggestionBlacklist.any_instance.stubs(should_correct?: true)

      stub_elasticsearch_request(
        '/mainstream,government/_search' => { suggest: { spelling_suggestions: 'a-hash' } }
      )

      es_response = UnifiedSearch::SpellCheckFetcher.new(SearchParameters.new(query: 'bolo'), stub('registries')).es_response

      assert_equal es_response, { 'spelling_suggestions' => 'a-hash' }
    end
  end
end
