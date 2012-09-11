require "integration_test_helper"
require "popular_items"
require 'gds_api/test_helpers/content_api'

class BrowseTest < IntegrationTest
  include GdsApi::TestHelpers::ContentApi

  def setup
    super
    mock_panopticon_api = mock("mock_panopticon_api")
    mock_panopticon_api.stubs(:curated_lists).returns({})
    GdsApi::Panopticon.stubs(:new).returns(mock_panopticon_api)

    content_api_has_root_sections([])
  end

  def content_api_has_artefacts(section="section-name", body = {})
    stub_request(:get,
      "https://contentapi.test.alphagov.co.uk/with_tag.json?include_children=1&tag=#{section}").
      to_return(:status => 200, :body => body.to_json)
  end

  def test_browsing_a_valid_section
    @primary_solr.stubs(:section).returns([sample_document])
    content_api_has_root_sections(['bob'])
    content_api_has_artefacts("bob")

    get "/browse/bob"
    assert last_response.ok?
  end

  def test_browsing_an_empty_section
    @primary_solr.stubs(:section).returns([])
    content_api_has_root_sections(["bob"])
    get "/browse/bob"
    assert_equal 404, last_response.status
  end

  def test_browsing_an_invalid_section
    @primary_solr.stubs(:section).returns([sample_document])

    get "/browse/And%20this"
    assert_equal 404, last_response.status
  end

  def test_browsing_a_section_shows_formatted_section_name
    @primary_solr.stubs(:section).returns([sample_document])
    content_api_has_root_sections(['this-and-that'])
    content_api_has_artefacts("this-and-that")

    get "/browse/this-and-that"
    assert_match /This and that/, last_response.body
  end

  def test_browsing_a_section_shows_custom_formatted_section_name
    @primary_solr.stubs(:section).returns([sample_document])
    content_api_has_root_sections(['life-in-the-uk'])
    content_api_has_artefacts("life-in-the-uk")

    get "/browse/life-in-the-uk"
    assert_match /Life in the UK/, last_response.body
  end

  def test_browsing_a_section_with_popular_item_shows_popular_item_at_top_of_page
    mock_panopticon_api = mock("mock_panopticon_api")
    mock_panopticon_api.stubs(:curated_lists).returns("section-name" => ["article-slug", "article-slug-two"])
    GdsApi::Panopticon.stubs(:new).returns(mock_panopticon_api)
    content_api_has_artefacts

    content_api_has_root_sections(['section-name'])
    doc = Document.from_hash(
      "title" => "The Popular Article",
      "description" => "DESCRIPTION",
      "format" => "local_transaction",
      "section" => "Life in the UK",
      "link" => "/article-slug"
    )
    @primary_solr.stubs(:section).returns([doc])

    get "/browse/section-name"
    response = Nokogiri.parse(last_response.body)
    assert_equal 1, response.css("#popular .results-list li a").size
    assert_match /The Popular Article/, response.css("#popular .results-list li a").inner_text
  end

  def test_ordering_of_popular_items_is_correct
    mock_panopticon_api = mock("mock_panopticon_api")
    mock_panopticon_api.stubs(:curated_lists).returns("section-name" => ["article-slug", "article-slug2", "article-slug3", "article-slug4"])
    GdsApi::Panopticon.stubs(:new).returns(mock_panopticon_api)
    content_api_has_artefacts

    doc1 = Document.from_hash(
      "title" => "The Popular Service",
      "description" => "DESCRIPTION",
      "format" => "local_transaction",
      "section" => "Life in the UK",
      "link" => "/article-slug"
    )

    doc2 = Document.from_hash(
      "title" => "The Popular Quick Answer",
      "description" => "DESCRIPTION",
      "format" => "smart_answer",
      "section" => "Life in the UK",
      "link" => "/article-slug2"
    )

    doc3 = Document.from_hash(
      "title" => "The Popular Guide",
      "description" => "DESCRIPTION",
      "format" => "guide",
      "section" => "Life in the UK",
      "link" => "/article-slug3"
    )

    doc4 = Document.from_hash(
      "title" => "The Popular Programme",
      "description" => "DESCRIPTION",
      "format" => "programme",
      "section" => "Life in the UK",
      "link" => "/article-slug4"
    )
    @primary_solr.stubs(:section).returns([doc1, doc2, doc3, doc4])
    content_api_has_root_sections(['section-name'])
    get "/browse/section-name"
    response = Nokogiri.parse(last_response.body)

    assert_match /The Popular Guide/, response.css("#popular .results-list li:first-child a").inner_text
    assert_match /The Popular Quick Answer/, response.css("#popular .results-list li:nth-child(2) a").inner_text
    assert_match /The Popular Service/, response.css("#popular .results-list li:nth-child(3) a").inner_text
    assert_match /The Popular Programme/, response.css("#popular .results-list li:last-child a").inner_text
  end

  def test_browsing_a_section_is_ordered_by_subsection_not_formats
    doc = Document.from_hash(
      "title" => "Item 1",
      "format" => "answer"
    )
    @primary_solr.stubs(:section).returns([doc])
    content_api_has_root_sections(['section-name'])
    content_api_has_artefacts

    get "/browse/section-name"

    response = Nokogiri.parse(last_response.body)
    assert_match /Other/, response.css("h2").inner_text
    assert_not_match /Answer/, response.css("h2").inner_text
  end

  def test_browsing_section_displays_other_sections
    @primary_solr.stubs(:section).returns([sample_document])
    content_api_has_root_sections(['bar', 'section-name', 'zulu'])
    content_api_has_artefacts
    get "/browse/section-name"

    response = Nokogiri.parse(last_response.body)
    other_sections = response.xpath("//h2[text() = 'Other sections']/following-sibling::ul/li/a").map(&:text)
    assert_equal ['Bar', 'Zulu'], other_sections
  end

  def test_browsing_section_correctly_escapes_entities_in_results
    doc = Document.from_hash({
      "title" => "This & That",
      "description" => "Description of This & That",
      "format" => "local_transaction",
      "section" => "life-in-the-uk",
      "link" => "/foo?bar=baz&foo=bar"
    })

    @primary_solr.stubs(:section).returns([doc])
    content_api_has_artefacts
    PopularItems.any_instance.stubs(:select_from).returns([doc])

    # Slimmer will raise xml parsing errors if there are unescaped entities
    assert_nothing_raised do
      content_api_has_root_sections(['section-name'])
      get "/browse/section-name"
    end

    assert last_response.ok?, "Expected response to be success"
  end

  def test_should_put_browse_in_section_nav_for_slimmer
    get "/browse"

    assert_equal "section nav", last_response.headers["X-Slimmer-Section"]
  end

  def test_should_put_section_in_section_nav_for_slimmer
    @primary_solr.stubs(:section).returns([sample_document])
    content_api_has_root_sections(['section-name'])
    content_api_has_artefacts
    get "/browse/section-name"

    assert_equal "section nav", last_response.headers["X-Slimmer-Section"]
  end

  def test_should_handle_timeouts_in_with_tags
    @primary_solr.stubs(:section).returns([sample_document])
    content_api_has_root_sections(['section-name'])
    stub_request(:get,
      "https://contentapi.test.alphagov.co.uk/with_tag.json?include_children=1&tag=section-name").to_timeout
    get "/browse/section-name"

    assert_equal 503, last_response.status
  end

  def test_browsing_section_list
    content_api_has_root_sections(["bob"])

    get "/browse"
    assert last_response.ok?
  end

  def test_browsing_section_list_should_not_add_item_to_breadcrumb_trail
    content_api_has_root_sections(["bob"])

    get "/browse"

    response = Nokogiri.parse(last_response.body)
    assert response.at_css("meta[name=x-section-link]").nil?
    assert response.at_css("meta[name=x-section-name]").nil?
  end

  def test_section_list_always_renders
    get "/browse"
    assert last_response.ok?
  end

  def test_should_provide_list_of_sections_via_json
    content_api_has_root_sections(["bob"])

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

    content_api_has_root_sections(['bob'])
    @primary_solr.stubs(:section).returns([doc])

    get '/browse/bob.json'

    assert last_response.ok?
    assert_match 'application/json', last_response.headers["Content-Type"]
    assert JSON.parse(last_response.body)
  end
end
