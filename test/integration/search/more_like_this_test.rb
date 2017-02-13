require "integration_test_helper"

class MoreLikeThisTest < IntegrationTest
  def setup
    # `@@registries` are set in Rummager and is *not* reset between tests. To
    # prevent caching issues we manually clear them here to make a "new" app.
    Rummager.class_variable_set(:'@@registries', nil)
    super
  end

  def test_returns_success
    get "/search?similar_to=/mainstream-1"

    assert last_response.ok?
  end

  def test_returns_similar_docs
    # We need at least 5 documents in the index for "more like this"
    # queries to work (default value of `min_doc_freq` in Elasticsearch)
    populate_content_indexes(section_count: 15)

    get "/search?similar_to=/mainstream-1&count=15&start=0"

    # All mainstream documents (excluding the one we're using for comparison)
    # should be returned, but none of the government ones, since they're not
    # "similar" enough
    assert result_links.include? "/mainstream-2"
    assert result_links.include? "/mainstream-3"
    assert result_links.include? "/mainstream-4"
    assert result_links.include? "/mainstream-5"
    refute result_links.include? "/mainstream-1"
    refute result_links.include? "/government-1"
    refute result_links.include? "/government-2"
    refute result_links.include? "/government-3"
    refute result_links.include? "/government-4"
    refute result_links.include? "/government-5"
  end

private

  def result_links
    @_result_links ||= parsed_response["results"].map do |result|
      result["link"]
    end
  end
end
