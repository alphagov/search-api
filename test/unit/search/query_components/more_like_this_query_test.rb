require "test_helper"
require "search/query_builder"

class MoreLikeThisQueryTest < ShouldaUnitTestCase
  context "more like this" do
    should "call the payload for a more like this query" do
      params = search_query_params(similar_to: %{"/hello-world"})
      builder = QueryComponents::Query.new(
        search_params: params,
        metasearch_index: Rummager.search_config.metasearch_index,
        content_index_names: Rummager.search_config.content_index_names
      )

      builder.expects(:more_like_this_query_hash).once

      builder.payload
    end
  end
end
