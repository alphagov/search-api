require "test_helper"
require_relative "../../lib/popular_items"

class PopularItemsTest < Test::Unit::TestCase
  def setup
    mock_panopticon_api = mock("mock_panopticon_api")
    mock_panopticon_api.expects(:curated_lists).returns("section-name" => ["article-slug", "article-slug-two"])
    GdsApi::Panopticon.expects(:new).returns(mock_panopticon_api)
    @popular_items = PopularItems.new({})
  end

  test "can select popular items from solr results by slug" do
    solr_results = [
      Document.from_hash("title" => 'Life in the UK', "link" => "/life-in-the-uk"),
      Document.from_hash("title" => 'Article Title', "link" => "/article-slug")
    ]

    items = @popular_items.select_from('section-name', solr_results)
    assert_equal 1, items.count
    assert_equal 'Article Title', items.first.title
  end

  test "order of popular items is controlled by the file" do
    solr_results = [
      Document.from_hash("title" => 'Two', "link" => "/article-slug-two"),
      Document.from_hash("title" => 'One', "link" => "/article-slug")
    ]

    items = @popular_items.select_from('section-name', solr_results)
    assert_equal %w{One Two}, items.map(&:title)
  end  
end
