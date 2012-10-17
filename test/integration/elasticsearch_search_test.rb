require "integration_test_helper"
require "app"
require "rest-client"

class ElasticsearchSearchTest < IntegrationTest

  def setup
    use_elasticsearch_for_primary_search
    app.any_instance.stubs(:secondary_search).returns(stub(search: []))
    WebMock.disable_net_connect!(allow: "localhost:9200")
    reset_elasticsearch_index
    add_sample_documents
    commit_index
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
        "title" => "Pork pies",
        "link" => "/pork-pies"
      }
    ]
  end

  def add_sample_documents
    sample_document_attributes.each do |sample_document|
      post "/documents", JSON.dump(sample_document)
      assert last_response.ok?
    end
  end

  def commit_index
    post "/commit", nil
  end

  def assert_result_links(*links)
    parsed_response = JSON.parse(last_response.body)
    assert_equal links, parsed_response.map { |r| r["link"] }
  end

  def test_should_search_by_content
    get "/search.json?q=badger"
    assert last_response.ok?
    assert_result_links "/an-example-answer"
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
      assert_nothing_raised "Request failed for '#{term}'" do
        get "/search.json?q=#{CGI.escape term}"
      end
      assert last_response.ok?
      assert_result_links "/an-example-answer"
    end
  end

  def test_should_not_parse_conjunctions_in_words
    # Testing a SHOUTY QUERY because Lucene only treats capitalised
    # conjunctions as special operators
    get "/search.json?q=PORK+PIES"
    assert last_response.ok?
    assert_result_links "/pork-pies"
  end
end
