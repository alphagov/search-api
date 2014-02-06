require "integration_test_helper"
require "app"
require "rest-client"

class CombinedSearchTest < IntegrationTest

  INDEX_NAMES = ["mainstream_test", "detailed_test", "government_test"]

  def setup
    stub_elasticsearch_settings(INDEX_NAMES)
    app.settings.search_config.stubs(:govuk_index_names).returns(INDEX_NAMES)
    enable_test_index_connections

    INDEX_NAMES.each do |index_name|
      try_remove_test_index(index_name)
      create_test_index(index_name)
      add_sample_documents(index_name, 2)
      commit_index(index_name)
    end
  end

  def teardown
    INDEX_NAMES.each do |index_name|
      clean_index_group(index_name)
    end
  end

  def sample_document_attributes(index_name, count)
    short_index_name = index_name.sub("_test", "")
    (1..count).map do |i|
      {
        "title" => "Sample #{short_index_name} document #{i}",
        "link" => "/#{short_index_name}-#{i}",
        "indexable_content" => "Something something important content"
      }
    end
  end

  def add_sample_documents(index_name, count)
    attributes = sample_document_attributes(index_name, count)
    attributes.each do |sample_document|
      post "/#{index_name}/documents", MultiJson.encode(sample_document)
      assert last_response.ok?
    end
  end

  def commit_index(index_name)
    post "/#{index_name}/commit", nil
  end

  def parsed_response
    MultiJson.decode(last_response.body)
  end

  def test_returns_success
    get "/govuk/search?q=important"
    assert last_response.ok?
  end

  def test_returns_streams
    get "/govuk/search?q=important"
    expected_streams = [
      "top-results",
      "services-information",
      "departments-policy"
    ].to_set
    assert_equal expected_streams, parsed_response["streams"].keys.to_set
  end

  def test_returns_3_top_results
    get "/govuk/search?q=important"
    assert_equal 3, parsed_response["streams"]["top-results"]["results"].count
  end

  def test_returns_spelling_suggestions
    get "/govuk/search?q=afgananistan"
    assert parsed_response["spelling_suggestions"].include? "Afghanistan"
  end
end
