require "integration_test_helper"
require "app"
require "rest-client"

class ElasticsearchSearchTest < IntegrationTest

  def setup
    stub_elasticsearch_settings
    enable_test_index_connections
    try_remove_test_index

    create_test_indexes
    add_sample_documents
    commit_index
  end

  def teardown
    clean_test_indexes
  end

  def sample_document_attributes
    [
      {
        "title" => "Cheese in my face",
        "description" => "Hummus weevils",
        "format" => "answer",
        "link" => "/an-example-answer",
        "indexable_content" => "I like my badger: he is tasty and delicious"
      },
      {
        "title" => "Useful government information",
        "description" => "Government, government, government. Developers.",
        "format" => "answer",
        "link" => "/another-example-answer",
        "section" => "Crime",
        "indexable_content" => "Tax, benefits, roads and stuff"
      },
      {
        "title" => "Temporary closure of British Embassy in Mali",
        "description" => "Mali",
        "format" => "edition",
        "search_format_types" => ["edition", "announcement"],
        "link" => "/mali-3",
        "section" => "",
        "indexable_content" => "Mali",
        "public_timestamp" => "2011-01-02"
      },
      {
        "title" => "Temporary closure of British Embassy in Mali",
        "description" => "Mali",
        "format" => "edition",
        "search_format_types" => ["edition", "announcement"],
        "link" => "/mali-2",
        "section" => "",
        "indexable_content" => "Mali",
        "public_timestamp" => "2012-01-02"
      },
      {
        "title" => "Temporary closure of British Embassy in Mali",
        "description" => "Mali",
        "format" => "edition",
        "search_format_types" => ["edition", "announcement"],
        "link" => "/mali-1",
        "section" => "",
        "indexable_content" => "Mali",
        "public_timestamp" => "2013-01-02"
      },
      {
        "title" => "Pork pies",
        "link" => "/pork-pies"
      },
      {
        "title" => "Written by the Home Office",
        "link" => "/written-by-ho",
        "indexable_content" => "Written by the Home Office",
        "organisations" => "home-office"
      },
    ]
  end

  def add_sample_documents
    sample_document_attributes.each do |sample_document|
      post "/documents", sample_document.to_json
      assert last_response.ok?
    end
  end

  def commit_index
    post "/commit", nil
  end

  def assert_result_links(*expected_links)
    order = true
    if expected_links[-1].is_a?(Hash)
      hash = expected_links.pop
      order = hash[:order]
    end

    parsed_response = JSON.parse(last_response.body)
    case parsed_response
      when Hash
        result_links = parsed_response["results"].map { |r| r["link"] }
      when Array
        result_links = parsed_response.map { |r| r["link"] }
      else
        raise "I don't know how to parse #{parsed_response.class}"
    end
    if order
      assert_equal expected_links, result_links
    else
      assert_equal expected_links.sort, result_links.sort
    end
  end

  def test_documents_with_public_timestamp_exhibit_a_decay_boost
    get "/search.json?q=mali"
    assert last_response.ok?
    assert_result_links "/mali-1", "/mali-2", "/mali-3"
  end

  def test_should_search_by_content
    get "/search.json?q=badger"
    assert last_response.ok?
    assert_result_links "/an-example-answer"
  end

  def test_can_scope_by_organisation
    get "/search.json?q=written&organisation_slug=home-office"
    assert last_response.ok?
    assert_result_links "/written-by-ho"
  end

  def test_no_results_when_scoped_by_organisation
    get "/search.json?q=written&organisation_slug=ministry-of-justice"
    assert last_response.ok?
    assert_result_links # assert no results
  end

  def test_can_sort_results_by_date
    get "/search.json?q=mali&sort=public_timestamp&order=asc"
    assert last_response.ok?
    # Results should come out oldest-first
    assert_result_links "/mali-3", "/mali-2", "/mali-1", order: true
  end

  def test_should_match_stems
    get "/search.json?q=badgers"
    assert last_response.ok?
    assert_result_links "/an-example-answer"
  end

  def test_should_search_by_title
    get "/search.json?q=cheese"
    assert last_response.ok?
    assert_result_links "/an-example-answer"
  end

  def test_should_search_by_description
    get "/search.json?q=hummus"
    assert last_response.ok?
    assert_result_links "/an-example-answer"
  end

  def test_should_not_match_on_slug
    ["example", "%2Fan-example-answer"].each do |escaped_query|
      get "/search.json?q=#{escaped_query}"
      assert last_response.ok?
      assert_no_results
    end
  end

  def test_should_escape_lucene_characters
    ["badger)", "badger\\"].each do |problem|
      get "/search.json?q=#{CGI.escape(problem)}"
      assert last_response.ok?
      assert_result_links "/an-example-answer"
    end
  end

  def test_should_not_match_on_format
    get "/search.json?q=answer"
    assert last_response.ok?
    assert_no_results
  end

  def test_should_not_match_on_section
    get "/search.json?q=crime"
    assert last_response.ok?
    assert_no_results
  end

  def test_should_not_fail_on_conjunctions
    ["cheese AND ", "cheese OR ", " AND cheese", " OR cheese"].each do |term|
      get "/search.json?q=#{CGI.escape term}"
      assert last_response.ok?
      assert_result_links "/an-example-answer"
    end
  end

  def test_should_not_fail_on_NOT
    get "/search.json?q=NOT"
    assert last_response.ok?
  end

  def test_should_not_parse_conjunctions_in_words
    # Testing a SHOUTY QUERY because Lucene only treats capitalised
    # conjunctions as special operators
    get "/search.json?q=PORK+PIES"
    assert last_response.ok?
    assert_result_links "/pork-pies"
  end
end
