require "test_helper"
require_relative "../../lib/popular_items"

class PopularItemsTest < Test::Unit::TestCase
  def setup
    @popular_items = PopularItems.new(File.expand_path('../fixtures/popular_items_sample.txt', File.dirname(__FILE__)))
  end

  test "can read popular items from file" do
    assert_equal 1, @popular_items.items.count
  end

  test "items are stored indexed by the section parameter" do
    assert_equal 2, @popular_items.items['section-name'].count
  end

  test "can check if a slug is popular" do
    assert @popular_items.popular?('section-name', 'article-slug')
    assert ! @popular_items.popular?('section-name', 'not-popular')
    assert ! @popular_items.popular?('other-section', 'article-slug')
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
