require "integration_test_helper"
require "app"
require "rest-client"

class ElasticsearchAdvancedSearchTest < IntegrationTest

  def setup
    @index_name = "mainstream_test"

    stub_elasticsearch_settings([@index_name])
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
        "indexable_content" => "I like my badger: he is tasty and delicious",
        "relevant_to_local_government" => true,
        "updated_at" => "2012-01-01"
      },
      {
        "title" => "Useful government information",
        "description" => "Government, government, government. Developers.",
        "format" => "answer",
        "link" => "/another-example-answer",
        "section" => "Crime",
        "indexable_content" => "Tax, benefits, roads and stuff",
        "relevant_to_local_government" => false,
        "updated_at" => "2012-01-03"
      },
      {
        "title" => "Cheesey government information",
        "description" => "Government, government, government. Developers.",
        "format" => "answer",
        "link" => "/yet-another-example-answer",
        "section" => "Crime",
        "indexable_content" => "Tax, benefits, roads and stuff, mostly about cheese",
        "relevant_to_local_government" => true,
        "updated_at" => "2012-01-04",
        "organisations" => ["ministry-of-cheese"]
      },
      {
        "title" => "Pork pies",
        "link" => "/pork-pies",
        "relevant_to_local_government" => true,
        "updated_at" => "2012-01-02"
      },
      {
        "title" => "Doc with attachments",
        "link" => "/doc-with-attachments",
        "attachments" => [
          {
            "title" => "Special thing",
            "command_paper_number" => "1234"
          }
        ]
      }
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

  def assert_result_links(*links)
    order = true
    if links[-1].is_a?(Hash)
      hash = links.pop
      order = hash[:order]
    end
    parsed_response = JSON.parse(last_response.body)
    parsed_links = parsed_response['results'].map { |r| r["link"] }
    if order
      assert_equal links, parsed_links
    else
      assert_equal links.sort, parsed_links.sort
    end
  end

  def assert_result_total(total)
    parsed_response = JSON.parse(last_response.body)
    assert_equal total, parsed_response['total']
  end

  def test_should_search_by_keywords
    get "/#{@index_name}/advanced_search.json?per_page=1&page=1&keywords=cheese"
    assert last_response.ok?
    assert_result_total 2
    assert_result_links "/an-example-answer"
  end

  def test_should_search_by_nested_data
    get "/#{@index_name}/advanced_search.json?per_page=1&page=1&keywords=#{CGI.escape('Special thing')}"
    assert last_response.ok?
    assert_result_total 1
    assert_result_links "/doc-with-attachments"
  end

  def test_should_escape_lucene_characters
    ["badger)", "badger\\"].each do |problem|
      get "/#{@index_name}/advanced_search.json?per_page=1&page=1&keywords=#{CGI.escape(problem)}"
      assert last_response.ok?
      assert_result_links "/an-example-answer"
    end
  end

  def test_should_allow_paging_through_keyword_search
    get "/#{@index_name}/advanced_search.json?per_page=1&page=2&keywords=cheese"
    assert last_response.ok?
    assert_result_total 2
    assert_result_links "/yet-another-example-answer"
  end

  def test_should_filter_results_by_a_property
    get "/#{@index_name}/advanced_search.json?per_page=2&page=1&section=Crime"
    assert last_response.ok?
    assert_result_total 2
    assert_result_links "/another-example-answer", "/yet-another-example-answer", order: false
  end

  def test_should_filter_results_by_a_nested_property
    get "/#{@index_name}/advanced_search.json?per_page=2&page=1&attachments.command_paper_number=1234"
    assert last_response.ok?
    assert_result_total 1
    assert_result_links "/doc-with-attachments"
  end

  def test_should_allow_boolean_filtering
    get "/#{@index_name}/advanced_search.json?per_page=3&page=1&relevant_to_local_government=true"
    assert last_response.ok?
    assert_result_total 3
    assert_result_links "/an-example-answer", "/yet-another-example-answer", "/pork-pies", order: false
  end

  def test_should_allow_date_filtering
    get "/#{@index_name}/advanced_search.json?per_page=3&page=1&updated_at[before]=2012-01-03"
    assert last_response.ok?
    assert_result_total 3
    assert_result_links "/an-example-answer", "/another-example-answer", "/pork-pies", order: false
  end

  def test_should_allow_combining_all_filters
    # add another doc to make the filter combination need everything to pick
    # the one we want
    more_documents = [
      {
        "title" => "Government cheese",
        "description" => "Government, government, government. cheese.",
        "format" => "answer",
        "link" => "/cheese-example-answer",
        "section" => "Crime",
        "indexable_content" => "Cheese tax.  Cheese recipies.  Cheese music.",
        "relevant_to_local_government" => true,
        "updated_at" => "2012-01-01"
      }
    ]
    more_documents.each do |sample_document|
      post "/documents", sample_document.to_json
      assert last_response.ok?
    end
    commit_index

    get "/#{@index_name}/advanced_search.json?per_page=3&page=1&relevant_to_local_government=true&updated_at[after]=2012-01-02&keywords=tax&section=Crime"

    assert last_response.ok?
    assert_result_total 1
    assert_result_links "/yet-another-example-answer"
  end

  def test_should_not_expand_organisations
    # The new organisation registry expands organisations from slugs into
    # hashes; for backwards compatibility, we shouldn't do this until it's
    # configured (and until clients can handle either format).
    get "/#{@index_name}/advanced_search.json?per_page=3&page=1&relevant_to_local_government=true&updated_at[after]=2012-01-02&keywords=tax&section=Crime"

    assert last_response.ok?
    assert_result_total 1
    parsed_response = JSON.parse(last_response.body)
    assert_equal ["ministry-of-cheese"], parsed_response["results"][0]["organisations"]
  end

  def test_should_allow_ordering_by_properties
    get "/#{@index_name}/advanced_search.json?per_page=4&page=1&order[updated_at]=desc"
    assert last_response.ok?
    assert_result_total 5
    assert_result_links "/yet-another-example-answer", "/another-example-answer", "/pork-pies", "/an-example-answer"
  end
end
