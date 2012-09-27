require "integration_test_helper"
require "app"
require "rest-client"

class ElasticsearchBrowsingTest < IntegrationTest

  def setup
    use_elasticsearch_for_primary_search
    disable_secondary_search
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
        "section" => "crime-and-justice",
        "indexable_content" => "I like my badger: he is tasty and delicious"
      },
      {
        "title" => "Useful government information",
        "description" => "Government, government, government. Developers.",
        "format" => "answer",
        "link" => "/another-example-answer",
        "section" => "work",
        "indexable_content" => "Tax, benefits, roads and stuff"
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

  def test_should_list_sections
    get "/browse"
    assert_links "Crime and justice" => "/browse/crime-and-justice",
                 "Work" => "/browse/work"
  end

  def test_should_list_documents_in_section
    # This is an old and crufty way of hacking around Slimmer, but we're about
    # to kill off all front-end functionality from Rummager, so there's little
    # point in doing things nicely
    stub_request(:get, "https://panopticon.test.alphagov.co.uk/curated_lists.json").
      to_return(body: "{}")

    get "/browse/work"
    assert_links "Useful government information" => "/another-example-answer"
    refute_links "Cheese in my face" => "/an-example-answer"
  end

end
