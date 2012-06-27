require_relative "integration_helper"
require "popular_items"

class BrowseTest < IntegrationTest
  def setup
    super
    mock_panopticon_api = mock("mock_panopticon_api")
    mock_panopticon_api.stubs(:curated_lists).returns({})
    GdsApi::Panopticon.stubs(:new).returns(mock_panopticon_api)
  end

  def test_browsing_a_valid_section
    @solr.stubs(:section).returns([sample_document])

    get "/browse/bob"
    assert last_response.ok?
  end

  def test_browsing_an_empty_section
    @solr.stubs(:section).returns([])

    get "/browse/bob"
    assert_equal 404, last_response.status
  end

  def test_browsing_an_invalid_section
    @solr.stubs(:section).returns([sample_document])

    get "/browse/And%20this"
    assert_equal 404, last_response.status
  end

  def test_browsing_a_section_shows_formatted_section_name
    @solr.stubs(:section).returns([sample_document])

    get "/browse/this-and-that"
    assert_match /This and that/, last_response.body
  end

  def test_browsing_a_section_shows_custom_formatted_section_name
    @solr.stubs(:section).returns([sample_document])

    get "/browse/life-in-the-uk"
    assert_match /Life in the UK/, last_response.body
  end

  def test_browsing_a_section_with_popular_item_shows_popular_item_at_top_of_page
    mock_panopticon_api = mock("mock_panopticon_api")
    mock_panopticon_api.stubs(:curated_lists).returns("section-name" => ["article-slug", "article-slug-two"])
    GdsApi::Panopticon.stubs(:new).returns(mock_panopticon_api)

    doc = Document.from_hash(
      "title" => "The Popular Article",
      "description" => "DESCRIPTION",
      "format" => "local_transaction",
      "section" => "Life in the UK",
      "link" => "/article-slug"
    )
    @solr.stubs(:section).returns([doc])

    get "/browse/section-name"
    response = Nokogiri.parse(last_response.body)
    assert_equal 1, response.css(".popular .content-links li").size
    assert_match /The Popular Article/, response.css(".popular .content-links li").inner_text
  end

  def test_browsing_a_section_is_ordered_by_subsection_not_formats
    doc = Document.from_hash(
      "title" => "Item 1",
      "format" => "answer"
    )
    @solr.stubs(:section).returns([doc])

    get "/browse/section-name"

    response = Nokogiri.parse(last_response.body)
    assert_match /Other/, response.css("h2").inner_text
    assert_not_match /Answer/, response.css("h2").inner_text
  end

  def test_should_put_browse_in_section_nav_for_slimmer
    @solr.stubs(:facet).returns([])
    get "/browse"

    assert_equal "Section nav", last_response.headers["X-Slimmer-Section"]
  end

  def test_should_put_section_in_section_nav_for_slimmer
    @solr.stubs(:section).returns([])
    get "/browse/section-name"

    assert_equal "Section nav", last_response.headers["X-Slimmer-Section"]
  end

  def test_browsing_section_list
    @solr.stubs(:facet).returns([sample_section])

    get "/browse"
    assert last_response.ok?
  end

  def test_section_list_always_renders
    @solr.stubs(:facet).returns([])

    get "/browse"
    assert last_response.ok?
  end

  def test_should_provide_list_of_sections_via_json
    @solr.stubs(:facet).returns([sample_section])
    get '/browse.json'
    assert last_response.ok?
    assert_match 'application/json', last_response.headers["Content-Type"]
    assert JSON.parse(last_response.body)
  end

  def test_should_provide_section_listing_via_json
    doc = Document.from_hash(
      "title" => "The Popular Article",
      "description" => "DESCRIPTION",
      "format" => "local_transaction",
      "section" => "Life in the UK",
      "link" => "/article-slug"
    )
    @solr.stubs(:section).returns([doc])
    get '/browse/bob.json'
    assert last_response.ok?
    assert_match 'application/json', last_response.headers["Content-Type"]
    assert JSON.parse(last_response.body)
  end
end
